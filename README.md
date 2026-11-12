# AskAI: LLM features in a SwiftUI football app

An iOS app that uses a large language model (LLM) for two features, built to show
how to ship AI features **reliably**: structured output, validation, guardrails,
fallbacks, evals and tests, not just an API call.

- **Match summary:** tap a button and the AI turns real match data into a short summary card.
  The answer is structured JSON, validated in code before anything is shown.
- **Football chat:** a streaming chat assistant that stays on topic, refuses betting advice,
  admits when it has no live data, and resists prompt injection.

> Built with SwiftUI, Swift Concurrency and Swift Testing. Runs without an API key in **demo mode**.

<!-- Add screenshots or a short GIF here, e.g.:
![Match summary](Docs/images/summary.png) ![Chat](Docs/images/chat.png)
-->

---

## Run it

1. Open `LLMProject.xcodeproj` in Xcode and run the **LLMProject** scheme.
2. That's it. Without a key, the app runs in **demo mode** with sample answers (marked with a "Demo" label).

**To use a real model (free):**
1. Get a key at [Google AI Studio](https://aistudio.google.com).
2. Copy `LLMProject/Config/Secrets.example.xcconfig` to `LLMProject/Config/Secrets.xcconfig`
   (same folder; the file is ignored by git).
3. Set `GEMINI_API_KEY = your-key`, **without quotes**, and run again.

---

## Architecture

```
App (SwiftUI, MVVM)
 ├─ Chat/          ChatView, ChatViewModel, prompt builder, input limits
 ├─ Match/         MatchSummaryView, MatchSummaryViewModel, error messages
 └─ MatchFeature/  Match data, MatchSummary (decode + validate + schema),
                   prompt files (.md)
        │
        ▼ depends on
Packages/LLMKit   (local Swift package, knows nothing about football)
 ├─ LLMProviding         protocol every provider implements
 ├─ LLMClient            OpenAI-compatible HTTP client (Gemini): streaming, model fallback, timeouts
 ├─ OnDeviceLLMClient    Apple Foundation Models (on-device, offline)
 ├─ FallbackLLMClient    primary first, fallback on failure
 ├─ MockLLMClient        canned answers for tests, previews and demo mode
 └─ PromptTemplate / PromptStore   versioned prompt files with {{placeholders}}
```

The view models depend only on `LLMProviding`, so providers can be swapped or combined
without touching feature code. With a key, the app uses:

```swift
FallbackLLMClient(primary: LLMClient(/* Gemini */), fallback: OnDeviceLLMClient())
```

---

## How the match summary works

```
Match (real data) ──► user message  <match_data>{ … JSON … }</match_data>
match_summary.md  ──► system message (rules, examples, allowed players)
JSON Schema       ──► response_format (the shape the answer must have)
                         │
                         ▼  LLM
                  JSON text ──► decode ──► validate ──► SummaryCard
```

Three layers protect the output, because a prompt is a request, not a guarantee:

| Layer | Example |
|---|---|
| **Prompt** asks | "3 or 4 bullets, under 15 words, only facts from `<match_data>`" |
| **Schema** constrains the shape | `playerOfTheMatch` must be one of the match's real players (`enum`) |
| **Code** validates the content | bullet count, bullet length, player actually played |

If anything fails, the user sees a friendly message ("The AI's answer didn't look right,
so we didn't show it") and the technical error goes to the console.

---

## Design decisions

- **Streaming for chat, complete answers for JSON.** People can read half a sentence;
  code can't decode half a JSON object.
- **Model fallback inside the client.** If a model is retired (404), rate-limited (429),
  overloaded (503) or times out, the next model is tried.
- **Provider fallback around the client.** If Gemini fails entirely (e.g. offline), the
  on-device model answers. In a stream, it only switches **before** any text was shown,
  so two different answers are never glued together.
- **Prompts are versioned files, not strings in code.** Each request logs
  `📝 match_summary v3 · model`, so a bad answer can be traced to the exact prompt version.
- **Self-describing data.** Stats are `{ "home": 16, "away": 9 }`, not `[16, 9]`:
  every ambiguity removed from the data is a rule the prompt doesn't need.
- **Guardrails in code, not only in the prompt.** Chat input is limited to 500 characters,
  only the last 10 messages are sent as history, and failed or empty replies are never sent back to the model.
- **No secrets in git.** The key lives in an ignored `.xcconfig` and reaches the app through Info.plist.
  The project builds without it.

---

## Prompt engineering & evals

Prompts live in `LLMProject/MatchFeature/Resources/` as Markdown with front matter:

```markdown
---
id: chat_assistant
version: 2
---
You are a friendly football (soccer) expert inside a football app.
…
```

The chat prompt is evaluated against a fixed set of tricky inputs (off-topic, live data,
prompt injection, betting, normal questions), including **held-out** cases that don't appear
in the prompt's examples. Results per version are in [`Docs/prompt-evals.md`](Docs/prompt-evals.md).

Example finding: v1 refused "ignore your instructions" but **accepted "you are now a pirate"**:
a friendly role change slipped past a rule written only for obvious attacks. v2 adds an explicit
rule and example for role changes.

---

## Tests

Run with **⌘U** (the test plan runs both the app tests and the LLMKit package tests).
No test calls the network: `MockLLMClient` and a fake prompt store stand in.

| Area | What's covered |
|---|---|
| Prompt templates | front-matter parsing, quoted values, `{{placeholder}}` rendering, missing values |
| Prompt files | every `PromptID` loads from the bundle and renders completely |
| Match summary | decoding (incl. Markdown fences), validation, view model states |
| Error messages | every error type maps to a friendly message without technical details |
| Chat | sending, streaming, Stop, failures, input limits, history window |
| Fallback | primary/fallback for `complete` and `stream`, cancellation never falls back |

---

## Limitations

- **On-device fallback** requires a device where Apple Intelligence (Foundation Models) is available.
  Elsewhere it reports itself unavailable and the app shows a friendly error.
- **The API key ships inside the app** (Info.plist). Fine for a demo; a production app would call
  its own backend, which holds the key, rate-limits users and can change prompts remotely.
- Match data is a bundled sample. There is no live data, by design.

## Next steps

- Natural-language match search ("Arsenal home games where both teams scored" → filters)
- Retry with backoff before switching models
- Latency metrics (time to first token)
- An automated eval runner instead of manual runs
