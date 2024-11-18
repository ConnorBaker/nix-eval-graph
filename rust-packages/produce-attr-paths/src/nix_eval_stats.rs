use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NixEvalStats {
    cpu_time: f64,
    envs: Envs,
    gc: Gc,
    list: List,
    nr_avoided: u64,
    nr_exprs: u64,
    nr_function_calls: u64,
    nr_lookups: u64,
    nr_op_update_values_copied: u64,
    nr_op_updates: u64,
    nr_prim_op_calls: u64,
    nr_thunks: u64,
    sets: Sets,
    sizes: Sizes,
    symbols: Symbols,
    time: Time,
    values: Values,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Envs {
    bytes: u64,
    elements: u64,
    number: u64,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Gc {
    cycles: u64,
    heap_size: u64,
    total_bytes: u64,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct List {
    bytes: u64,
    concats: u64,
    elements: u64,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Sets {
    bytes: u64,
    elements: u64,
    number: u64,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "PascalCase")]
struct Sizes {
    attr: u64,
    bindings: u64,
    env: u64,
    value: u64,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Symbols {
    bytes: u64,
    number: u64,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Time {
    cpu: f64,
    gc: f64,
    gc_fraction: f64,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Values {
    bytes: u64,
    number: u64,
}
