# 1bit-engine v0.1.0

**Pure Rust inference engine for AMD Strix Halo.** Zero Python. Zero C++ at
the server layer. Wraps [rocm-cpp v0.2.0](https://github.com/bong-water-water-bong/rocm-cpp)
kernels behind an OpenAI-compatible HTTP API.

**Performance (ROCm 7.2.4, gfx1151, June 2026):**  
Decode: 27 µs at 6912×2560 = **7.8× rocBLAS FP16**  
Prefill: 21.9 TFlops at 2560×6912×2560 = 73% of rocBLAS, **2.9× per-byte**  
See [rocm-cpp benchmarks](https://github.com/bong-water-water-bong/rocm-cpp/blob/main/results/BENCHMARK-20260623.md) for full data.

## Architecture

```
onebit (:13305)   axum (Rust)  ←  your code here
  │
  └── bitnet_decode --server   rocm-cpp (C++/HIP)
       └── librocm_cpp.so      ternary GEMV/GEMV kernels
            └── gfx1151        Strix Halo iGPU
```

One binary. Spawns `bitnet_decode` as a subprocess, health-checks until ready,
proxies all `/v1/*` requests with streaming passthrough.

## Quick start

```bash
# Prerequisites: rocm-cpp built with bitnet_decode on PATH
git clone https://github.com/bong-water-water-bong/1bit-engine
cd 1bit-engine
cargo build --release

# Run with a .h1b model
./target/release/onebit --model path/to/model.h1b --port 13305
```

## Usage

```
USAGE:
    onebit [OPTIONS]

OPTIONS:
    -m, --model <MODEL>          Path to .h1b model file [default: ./model.h1b]
    -p, --port <PORT>            Port for the OpenAI-compatible API [default: 13305]
        --host <HOST>            Host to bind to [default: 127.0.0.1]
        --bitnet-decode <PATH>   Path to bitnet_decode binary [default: bitnet_decode]
        --backend-port <PORT>    Internal port for bitnet_decode [default: random]
        --bitnet-args <ARGS>     Extra args to pass to bitnet_decode [default: ""]
```

## Connect apps

```python
from openai import OpenAI
client = OpenAI(base_url="http://127.0.0.1:13305/v1", api_key="any")
print(client.chat.completions.create(
    model="bitnet",
    messages=[{"role":"user","content":"Hello"}],
    max_tokens=20,
).choices[0].message.content)
```

Any OpenAI-compatible client works — OpenWebUI, Continue.dev, Aider, n8n, Dify.

## Repos

| Repo | Role |
|---|---|
| [1bit-engine](https://github.com/bong-water-water-bong/1bit-engine) | Rust HTTP server (this repo) |
| [rocm-cpp](https://github.com/bong-water-water-bong/rocm-cpp) | C++/HIP kernels |
| [1bit-systems](https://github.com/bong-water-water-bong/1bit-systems) | Website, docs, benchmarks |

## License

MIT
