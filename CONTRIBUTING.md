# Contributing to 1bit-engine

## Setup
```bash
git clone https://github.com/bong-water-water-bong/1bit-engine
cd 1bit-engine
cargo build --release
cargo test --release
```

## Guidelines
- Pure Rust. No Python in the hot path.
- Keep the proxy simple — forward requests, don't transform.
- Add tests for any new feature.
- Run `cargo fmt` and `cargo clippy -- -D warnings` before PR.
- Use Conventional Commits.

## Architecture
```
onebit (:13305)  →  axum server  →  spawns bitnet_decode  →  proxy /v1/*
```

The server spawns a rocm-cpp subprocess and proxies OpenAI requests to it.
No other backends, no plugin system. Simple, fast, auditable.
