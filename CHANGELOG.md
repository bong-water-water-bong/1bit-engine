# Changelog

## [0.1.0] — 2026-06-23

- Initial release
- axum HTTP server wrapping bitnet_decode as subprocess
- OpenAI-compatible /v1/chat/completions, /v1/models, /v1/embeddings
- Streaming SSE passthrough, CORS, health checks
- CLI flags: --tune-prefill, --prefill-variant, --fp16-weights
- rustls-only TLS (zero system deps)
- 7 unit tests (health, CLI parsing, proxy error handling)
- One-command installer for Ubuntu/Arch/Fedora
