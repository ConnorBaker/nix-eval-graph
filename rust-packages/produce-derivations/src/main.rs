use axum::{extract::MatchedPath, http::Request, response::Json, routing::get, Router};
use itertools::Itertools;
use produce_derivations::nix_derivation_show::{nix_derivation_show, Args};
use tokio::net::TcpListener;
use tower_http::trace::TraceLayer;
use tracing::info_span;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};
use tracing_unwrap::ResultExt;

async fn produce_derivations_endpoint(Json(args): Json<Args>) -> Json<Vec<String>> {
    tracing::info!(
        "Got request with args: {}",
        serde_json::to_string(&args).expect_or_log(&*format!("{:?}", args))
    );
    // TODO(@connorbaker): Forward stderr somewhere.
    let (derivations, stderr, stats) = nix_derivation_show(&args.flake_ref, &args.attr_path);
    tracing::info!("Found {} derivations in the closure", derivations.len());
    if !stderr.is_empty() {
        tracing::warn!("nix search populated stderr: {:?}", stderr);
    }
    // TODO(@connorbaker): Will need the full derivations later.
    derivations
        .into_keys()
        .sorted_unstable()
        .collect::<Vec<_>>()
        .into()
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
        .route("/produce-derivations", get(produce_derivations_endpoint))
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

    let addr = "127.0.0.1:3001";
    let listener = TcpListener::bind(addr)
        .await
        .expect_or_log(&*format!("Couldn't bind to {}", addr));
    tracing::debug!("Listening on {}", addr);
    axum::serve(listener, app)
        .await
        .expect_or_log("Couldn't serve the app");
}
