use hashbrown::HashMap;
use itertools::Itertools;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::process::Command;
use tempfile::NamedTempFile;
use tracing_unwrap::{OptionExt, ResultExt};

use crate::nix_eval_stats::NixEvalStats;

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Args {
    pub flake_ref: String,
    pub attr_path: String,
}

pub fn nix_search(flake_ref: &str, attr_path: &str) -> (Vec<String>, String, NixEvalStats) {
    let full_ref = [flake_ref, attr_path].join("#");

    let nix_show_stats_path_file = NamedTempFile::new()
        .expect_or_log("Couldn't create a temporary file for NIX_SHOW_STATS_PATH");
    let nix_show_stats_path_str = nix_show_stats_path_file
        .path()
        .to_str()
        .expect_or_log("Couldn't get NIX_SHOW_STATS_PATH as file path");

    let output = Command::new("nix")
        .envs([
            ("NIX_SHOW_STATS", "1"),
            ("NIX_SHOW_STATS_PATH", nix_show_stats_path_str),
        ])
        .args([
            "search",
            &full_ref,
            // Match all found packages
            "^",
            // Format
            "--json",
            // Configuration flags
            "--no-allow-import-from-derivation",
            "--no-allow-unsafe-native-code-during-evaluation",
            "--no-eval-cache",
            "--pure-eval",
            "--quiet",
        ])
        .output()
        .expect_or_log(&*format!("Couldn't run nix search for {}", full_ref));

    let stdout = String::from_utf8(output.stdout).expect_or_log("Couldn't parse stdout");
    let stderr = String::from_utf8(output.stderr).expect_or_log("Couldn't parse stderr");
    let json_output = match serde_json::from_str::<HashMap<String, Value>>(&stdout) {
        Ok(json) => json,
        Err(parse_error) => {
            tracing::error!(?parse_error, stderr, stdout);
            panic!();
        }
    };

    let attr_path_prefix = attr_path.to_string() + ".";
    let relative_descendant_attr_paths = json_output.into_keys()
    .map(move |descendant_attr_path| {
        match descendant_attr_path.strip_prefix(&attr_path_prefix) {
            Some(relative_descendant_attr_path) => relative_descendant_attr_path.to_string(),
            None => {
                tracing::error!(
                    "Couldn't remove attribute path prefix {} from attribute path {} -- this should be impossible as attribute is contained within attribute path prefix", 
                    attr_path,
                    descendant_attr_path,
                );
                panic!();
            }
        }
    })
    .sorted_unstable()
    .collect::<Vec<String>>();

    let stats: NixEvalStats = match serde_json::from_reader(&nix_show_stats_path_file) {
        Ok(json) => json,
        Err(parse_error) => {
            tracing::error!(?parse_error, stderr, stdout);
            panic!("Couldn't parse JSON stats: {}", parse_error);
        }
    };
    nix_show_stats_path_file
        .close()
        .expect_or_log("Couldn't close NIX_SHOW_STATS_PATH file");

    (relative_descendant_attr_paths, stderr, stats)
}
