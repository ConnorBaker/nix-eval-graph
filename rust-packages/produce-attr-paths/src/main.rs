use std::{collections::HashMap, process::Command};

use clap::{command, Parser};
use serde::{Deserialize, Serialize};
use tempfile::NamedTempFile;

mod lib;

use crate::lib::NixEvalStats;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None, propagate_version = true)]
struct Args {
    /// A flake URI
    #[arg(short, long, default_value = ".")]
    flakeuri: String,

    /// An attribute path
    #[arg(
        short,
        long,
        default_value = "legacyPackages.x86_64-linux.python3Packages"
    )]
    attrpath: String,

    /// Regex for package filtering
    #[arg(short, long, default_value = "^")]
    regex: String,
}

#[derive(Serialize, Deserialize, Debug)]
struct Package {
    description: String,
    pname: String,
    version: String,
}

fn main() -> () {
    let args = Args::parse();

    let nix_show_stats_path_file =
        NamedTempFile::new().expect("Couldn't create a temporary file for NIX_SHOW_STATS_PATH.");
    let nix_show_stats_path_str = nix_show_stats_path_file
        .path()
        .to_str()
        .expect("Couldn't get NIX_SHOW_STATS_PATH file.");

    let output = Command::new("nix")
        .env("NIX_SHOW_STATS", "1")
        .env("NIX_SHOW_STATS_PATH", nix_show_stats_path_str)
        .arg("search")
        .arg(args.flakeuri + "#" + &args.attrpath)
        .arg(args.regex)
        .arg("--json")
        .output();

    match output {
        Ok(output) => {
            let stdout = String::from_utf8(output.stdout).expect("Couldn't parse stdout.");
            let stderr = String::from_utf8(output.stderr).expect("Couldn't parse stderr.");
            let json_output: HashMap<String, Package> =
                serde_json::from_str(&stdout).expect("Couldn't parse JSON.");
            let stats: NixEvalStats =
                serde_json::from_reader(nix_show_stats_path_file).expect("poo");
            println!(
                "{}",
                serde_json::to_string_pretty(&json_output).expect("sad1")
            );
            println!("{}", serde_json::to_string_pretty(&stats).expect("sad2"))
        }
        Err(e) => {
            eprintln!("Error: {}", e)
        }
    }
}
