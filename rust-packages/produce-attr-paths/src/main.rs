use std::{
    collections::HashMap,
    // io::{self, Write},
    process::Command,
};

use serde::{Deserialize, Serialize};

use clap::Parser;

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
#[command(propagate_version = true)]
struct Args {
    /// A flake URI
    #[arg(short, long, default_value = ".#")]
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

fn main() {
    let args = Args::parse();

    let output = Command::new("nix")
        .arg("search")
        .arg([args.flakeuri, args.attrpath].concat())
        .arg(args.regex)
        .arg("--json")
        .output()
        .expect("failed to execute process");

    // static VALUE: &str = r#"{
    //    "BCH": {
    //       "description": "currency",
    //       "pname": "BCH",
    //       "version": "10"
    //    }
    // }"#;
    let sting = String::from_utf8(output.stdout).expect("sadf");
    let serde_value: HashMap<String, Package> = serde_json::from_str(&sting).unwrap();
    println!("{:?}", serde_value);

    // io::stdout().fmt
    // println!("status: {}", output.status);
    // io::stdout().write_all(&output.stdout).unwrap();
    // io::stderr().write_all(&output.stderr).unwrap();
}
