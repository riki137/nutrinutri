/// The wire protocol a provider's API speaks.
///
/// Most providers expose an OpenAI-compatible `POST .../chat/completions`
/// endpoint; Anthropic uses its own Messages API (`POST .../messages`) with a
/// different request/response shape and auth headers.
enum AiApiProtocol {
  /// OpenAI-style chat completions (OpenRouter, OpenAI, Groq, Together, ...).
  openAiChat,

  /// Anthropic Messages API (Claude models via api.anthropic.com).
  anthropicMessages,
}
