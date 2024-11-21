use hashbrown::HashMap;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::process::Command;
use tempfile::NamedTempFile;
use tracing_unwrap::{OptionExt, ResultExt};

use produce_attr_paths::nix_eval_stats::NixEvalStats;

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Args {
    pub flake_ref: String,
    pub attr_path: String,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(untagged)]
#[serde(rename_all = "camelCase")]
pub enum Output {
    // {
    // "hash": "694db764812a6236423d4ff40ceb7b6c4c441301b72ad502bb5c27e00cd56f78",
    // "hashAlgo": "sha256",
    // "method": "flat",
    // "path": "/nix/store/czi5kvrk91zfjbfjrgvzbw9pgqz5dwx7-gawk-5.3.1.tar.xz"
    // }
    Fixed {
        hash: String,
        hash_algo: String,
        method: String,
        path: String,
    },
    // {
    // "path": "/nix/store/razasrvdg7ckplfmvdxv4ia3wbayr94s-bootstrap-tools"
    // }
    Dynamic {
        path: String,
    },
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct InputDerivation {
    // {
    // "dynamicOutputs": {},
    // "outputs": [
    //   "out"
    // ]
    // },
    pub dynamic_outputs: HashMap<String, Value>,
    pub outputs: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Derivation {
    // Args can be empty
    pub args: Vec<String>,

    // Example builders:
    // builtin:fetchurl
    // /nix/store/0irlcqx2n3qm6b1pc9rsd2i8qpvcccaj-bash-5.2p37/bin/bash
    // /nix/store/p9wzypb84a60ymqnhqza17ws0dvlyprg-busybox
    // /nix/store/razasrvdg7ckplfmvdxv4ia3wbayr94s-bootstrap-tools/bin/bash
    pub builder: String,

    // As environment variables, these are always strings.
    // NOTE: As a consequence of how Nix passes attributes to derivation environment variables, this will contain
    // fields like pname and version (if they existed in the attribute set).
    pub env: HashMap<String, String>,

    // TODO
    pub input_drvs: HashMap<String, InputDerivation>,

    // Always strings. Example:
    // [
    // "/nix/store/6b9v7v02npab086yaba2j4yfqrph5mgp-utils.bash",
    // "/nix/store/6xizqkp4bnhydwc7ihyqi93171gbj5n4-darwin-sdk-setup.bash",
    // "/nix/store/ckjykyfw30zj1n3lcca9lwm2lzd7azdb-setup-hook.sh",
    // "/nix/store/f1kvkfigync29bnh159frf9xchfm1dpm-cc-wrapper.sh",
    // "/nix/store/p86c38va977n9lyw1lqbxx0syl0vllph-add-flags.sh",
    // "/nix/store/v6x3cs394jgqfbi0a42pam708flxaphh-default-builder.sh",
    // "/nix/store/v9034cqc4h5bm10z4vz3n1q2n55grv5y-role.bash",
    // "/nix/store/zq22rvyy29sgnq9d6ypa4826s3v2fm1w-add-hardening.sh"
    // ]
    pub input_srcs: Vec<String>,
    pub name: String,
    pub outputs: HashMap<String, Output>,

    // Things like "x86_64-linux" or "builtin"
    pub system: String,
}

// TODO(@connorbaker): A lot of duplication between this and the call which wraps nix_search.
pub fn nix_derivation_show(
    flake_ref: &str,
    attr_path: &str,
) -> (HashMap<String, Derivation>, String, NixEvalStats) {
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
            "derivation",
            "show",
            // NOTE: No format flag since derivation show always outputs JSON.
            &full_ref,
            // Configuration flags
            "--no-allow-import-from-derivation",
            "--no-allow-unsafe-native-code-during-evaluation",
            "--no-eval-cache",
            "--pure-eval",
            "--quiet",
            "--recursive",
        ])
        .output()
        .expect_or_log(&*format!(
            "Couldn't run nix derivation show for {}",
            full_ref
        ));

    let stdout = String::from_utf8(output.stdout).expect_or_log("Couldn't parse stdout");
    let stderr = String::from_utf8(output.stderr).expect_or_log("Couldn't parse stderr");
    let derivations = match serde_json::from_str::<HashMap<String, Derivation>>(&stdout) {
        Ok(json) => json,
        Err(parse_error) => {
            tracing::error!(?parse_error, stderr, stdout);
            panic!();
        }
    };

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
    (derivations, stderr, stats)
}
