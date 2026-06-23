# CLAUDE.md — 1bit-engine

Pure Rust inference runtime for AMD Strix Halo. Zero Python, zero C++ at
the Rust layer. Wraps `bitnet_decode` (rocm-cpp) behind an OpenAI-compatible
HTTP API.

## Architecture

```
onebit (:13305)  —  axum HTTP server, pure Rust
  └── spawns bitnet_decode --server  —  rocm-cpp C++/HIP binary
       └── librocm_cpp.so  —  ternary GEMV/GEMV, 4.9-7.2x rocBLAS
```

## Hard rules

- **Zero Python.** No Python at runtime. Build-time scripts and model
  conversion are allowed.
- **Only Rust.** The server is Rust. The kernels are rocm-cpp (C++/HIP).
  No Node.js, no shell-script orchestration.
- **OpenAI-compatible.** `/v1/chat/completions`, `/v1/completions`,
  `/v1/models`, `/v1/embeddings` — standard OpenAI SDK clients work.
- **Streaming passthrough.** SSE streaming is proxied transparently.

## Run

```bash
cargo run -- --model model.h1b --port 13305
```

## Test

```bash
curl http://127.0.0.1:13305/health
curl http://127.0.0.1:13305/v1/models
curl http://127.0.0.1:13305/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"bitnet","messages":[{"role":"user","content":"Hello"}],"max_tokens":10}'
```

## What NOT to do

- Don't add Python to the hot path
- Don't add C++ to the server (kernels stay in rocm-cpp)
- Don't add Node.js or shell-script orchestration
- Don't depend on Lemonade SDK
