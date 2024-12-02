use axum::{extract::MatchedPath, http::Request, response::Json, routing::get, Router};
use produce_attr_paths::nix_search::{nix_search, Args};
use tokio::net::TcpListener;
use tower_http::trace::TraceLayer;
use tracing::info_span;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use tracing_unwrap::ResultExt;

async fn produce_attr_paths_endpoint(Json(args): Json<Args>) -> Json<Vec<String>> {
    tracing::info!(
        "Got request with args: {}",
        serde_json::to_string(&args).expect_or_log(&*format!("{:?}", args))
    );
    // TODO(@connorbaker): Forward stderr somewhere.
    let (relative_descendant_attr_paths, stderr, stats) =
        nix_search(&args.flake_ref, &args.attr_path);
    tracing::info!(
        "Finished with stats {}",
        serde_json::to_string(&stats).unwrap()
    );
    tracing::info!("Found {} packages", relative_descendant_attr_paths.len());
    if !stderr.is_empty() {
        tracing::warn!("nix search populated stderr: {:?}", stderr);
    }
    relative_descendant_attr_paths.into()
}

#[tokio::main]
async fn main() {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| {
                // axum logs rejections from built-in extractors with the `axum::rejection`
                // target, at `TRACE` level. `axum::rejection=trace` enables showing those events
                format!(
                    "{}=debug,tower_http=debug,axum::rejection=trace",
                    env!("CARGO_CRATE_NAME")
                )
                .into()
            }),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // build our application with a route
    let app = Router::new()
        .route("/produce-attr-paths", get(produce_attr_paths_endpoint))
        .layer(
            TraceLayer::new_for_http().make_span_with(|request: &Request<_>| {
                // Log the matched route's path (with placeholders not filled in).
                // Use request.uri() or OriginalUri if you want the real path.
                let matched_path = request
                    .extensions()
                    .get::<MatchedPath>()
                    .map(MatchedPath::as_str);

                info_span!(
                    "http_request",
                    method = ?request.method(),
                    matched_path,
                    latency = tracing::field::Empty,
                )
            }), // .on_request(|_request: &Request<_>, _span: &Span| {
                // })
                // .on_response(|_response: &Response, _latency: Duration, _span: &Span| {
                // })
                // .on_body_chunk(|_chunk: &Bytes, _latency: Duration, _span: &Span| {
                // })
                // .on_eos(
                //     |_trailers: Option<&HeaderMap>, _stream_duration: Duration, _span: &Span| {
                //     },
                // )
                // .on_failure(
                //     |_error: ServerErrorsFailureClass, _latency: Duration, _span: &Span| {
                //     },
                // ),
        );

    let addr = "0.0.0.0:3000";
    let listener = TcpListener::bind(addr)
        .await
        .expect_or_log(&*format!("Couldn't bind to {}", addr));
    tracing::debug!("Listening on {}", addr);
    axum::serve(listener, app)
        .await
        .expect_or_log("Couldn't serve the app");
}
