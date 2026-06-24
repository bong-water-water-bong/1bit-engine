# 1bit-engine v0.1.0

**Pure Rust inference engine for AMD Strix Halo.** Zero Python. Zero C++ at
the server layer. Wraps [rocm-cpp v0.2.0](https://github.com/bong-water-water-bong/rocm-cpp)
kernels behind an OpenAI-compatible HTTP API.

**Performance (ROCm 7.2.4, gfx1151, June 2026):**  
Decode: 27 µs at 6912×2560 = **7.8× rocBLAS FP16**  
Prefill: 21.9 TFlops at 2560×6912×2560 = 73% of rocBLAS, **2.9× per-byte**  
See [rocm-cpp benchmarks](https://github.com/bong-water-water-bong/rocm-cpp/blob/main/results/BENCHMARK-20260623.md)

## One-Command Install

```bash
curl -fsSL https://raw.githubusercontent.com/bong-water-water-bong/1bit-engine/main/install.sh | bash
```

Installs Rust, ROCm build deps, clones + builds rocm-cpp + 1bit-engine.
Works on Ubuntu 24.04, Arch, CachyOS, Fedora.

## Run

```bash
source ~/.cargo/env
export HSA_OVERRIDE_GFX_VERSION=11.5.1
export HSA_ENABLE_SDMA=0
~/1bit/engine/target/release/onebit --model model.h1b --port 13305 --tune-prefill --fp16-weights
```

## Connect

```python
from openai import OpenAI
client = OpenAI(base_url="http://127.0.0.1:13305/v1", api_key="any")
print(client.chat.completions.create(
    model="bitnet",
    messages=[{"role":"user","content":"Hello"}],
    max_tokens=20,
).choices[0].message.content)
```

## Repos

| Repo | Role |
|---|---|
| [1bit-engine](https://github.com/bong-water-water-bong/1bit-engine) | Rust HTTP server (this repo) |
| [rocm-cpp](https://github.com/bong-water-water-bong/rocm-cpp) | C++/HIP kernels |
| [1bit-systems](https://github.com/bong-water-water-bong/1bit-systems) | Website, docs, benchmarks |

## License

MIT
