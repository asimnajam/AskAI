# AskAI: LLM features in a SwiftUI football app

![Tests](https://github.com/asimnajam/AskAI/actions/workflows/tests.yml/badge.svg)

An iOS app that uses a large language model (LLM) for three features, built to show
how to ship AI features **reliably**: structured output, validation, guardrails,
fallbacks, evals, latency measurement and tests, not just an API call.

- **Match summary:** tap a button and the AI turns real match data into a short summary card.
  The answer is structured JSON, validated in code before anything is shown.
- **Smart search:** type a sentence like *"Liverpool home defeats"* and the AI turns it into
  filters. Your own code then filters the matches, so the AI never invents results.
  The filters appear as chips you can remove with a tap.
- **Football chat:** a streaming chat assistant that stays on topic, refuses betting advice,
  admits when it has no live data, and resists prompt injection.

> Built with SwiftUI, Swift Concurrency and Swift Testing. Runs without an API key in **demo mode**.

<!-- Add screenshots or a short GIF here, e.g.:
![Match summary](Docs/images/summary.png) ![Search](Docs/images/search.png) ![Chat](Docs/images/chat.png)
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
 ├─ Match/         match list + search UI, summary screen, view models, error messages
 └─ MatchFeature/  Match data and store, MatchSummary (decode + validate + schema),
                   MatchFilters (search filters + schema), prompt files (.md), matches.json
        │
        ▼ depends on
Packages/LLMKit   (local Swift package, knows nothing about football)
 ├─ LLMProviding             protocol every provider implements
 ├─ LLMClient                OpenAI-compatible HTTP client (Gemini): streaming, retries, model fallback
 ├─ RetryPolicy              exponential backoff with jitter, honours Retry-After
 ├─ OnDeviceLLMClient        Apple Foundation Models (on-device, offline)
 ├─ FallbackLLMClient        primary first, fallback on failure
 ├─ LatencyMeasuringClient   time to first token and total time per request
 ├─ MockLLMClient            canned answers for tests, previews and demo mode
 └─ PromptTemplate / PromptStore   versioned prompt files with {{placeholders}}
```

The view models depend only on `LLMProviding`, so providers can be swapped or combined
without touching feature code. With a key, the app composes them like this:

```swift
LatencyMeasuringClient(
    wrapping: FallbackLLMClient(
        primary: LLMClient(/* Gemini, with retries and model fallback */),
        fallback: OnDeviceLLMClient()
    )
)
```

Each wrapper adds one behaviour (measuring, falling back) around the same interface,
so new behaviour was added three times without changing any view model.

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

## How smart search works

The AI does the language part; Swift does everything else.

```
"Liverpool home defeats"
        │
        ▼  LLM (match_search.md + schema with the real team/player names)
{"team": "Liverpool", "venue": "home", "result": "loss"}
        │
        ▼  decode → MatchFilters → check names against the data
matches.filter(filters.matches)            ← plain Swift, fully unit-tested
        │
        ▼
[Liverpool] [Home] [Loss]   ← chips: what the AI understood, each removable with a tap
```

- **The AI never sees or invents results.** It only translates the sentence into filters.
- **Allowed names come from the data.** Teams, competitions and players are inserted into the
  prompt and the schema from `matches.json`, so they can't disagree.
- **All filter fields are optional** (no `required` list): the model sets only what the user mentioned.
- **Names are checked in code too.** The on-device fallback ignores schemas, so an invented
  team must be caught by Swift, not just by the API.
- **Keyword fallback.** If the AI fails, returns nothing (`{}` for "best pizza in town"),
  or uses an unknown name, a plain text search runs instead. Search works without the AI.
- **Removing a chip re-filters locally**, without another AI call: instant and free.
- **Search runs on submit, not on every keystroke**, and an older answer can never overwrite
  the results of a newer search.

---

## Reliability and latency

**Retries and fallbacks, from the inside out:**

| Problem | What happens |
|---|---|
| 429 (rate limited) or 5xx | wait ~0.5 s, then ~1 s (exponential backoff with jitter, or the server's `Retry-After`), retry the same model |
| still failing, 404, or timeout | try the next Gemini model |
| every Gemini model fails (e.g. offline) | Apple's on-device model answers |
| everything fails | a friendly message; the technical error is logged |
| the user taps Stop | everything stops; cancellation never triggers a retry or fallback |

**Latency is measured around all of it**, so the numbers include any retries or fallbacks
the user waited through:

```
⏱️ stream · first token 0.41 s · total 2.10 s · 486 chars
⏱️ match_summary v3 · total 1.84 s · 312 chars
⏱️ match_search v1 · total 0.92 s · 0 chars · failed
```

(Example output format.) For the chat, **time to first token** is what the user feels:
streaming shows the first words long before the full answer is ready.

---

## Design decisions

- **Streaming for chat, complete answers for JSON.** People can read half a sentence;
  code can't decode half a JSON object.
- **In a stream, fall back only before any text is shown**, so two different answers are never glued together.
- **Prompts are versioned files, not strings in code.** Each request logs
  `📝 match_summary v3 · model`, so a bad answer can be traced to the exact prompt version.
- **Self-describing data.** Stats are `{ "home": 16, "away": 9 }`, not `[16, 9]`:
  every ambiguity removed from the data is a rule the prompt doesn't need.
- **Temperature 0 for search and low for summaries:** translating and summarizing facts shouldn't be creative.
- **Guardrails in code, not only in the prompt.** Chat input is limited to 500 characters,
  only the last 10 messages are sent as history, and failed or empty replies are never sent back to the model.
- **No secrets in git.** The key lives in an ignored `.xcconfig` and reaches the app through Info.plist.
  The project builds without it, which is also how CI runs.

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

Prompts are evaluated against fixed sets of tricky inputs (off-topic, live data,
prompt injection, betting, normal questions), including **held-out** cases that don't appear
in the prompt's examples. Results per version are in [`Docs/prompt-evals.md`](Docs/prompt-evals.md).

Example finding: v1 refused "ignore your instructions" but **accepted "you are now a pirate"**:
a friendly role change slipped past a rule written only for obvious attacks. v2 adds an explicit
rule and example for role changes.

---

## Tests

115+ tests. Run with **⌘U**: the test plan runs both the app tests and the LLMKit package tests.
They also run on **GitHub Actions** (Xcode 27) on every push and pull request.
No test calls the network: `MockLLMClient` and a fake prompt store stand in.

| Area | What's covered |
|---|---|
| Prompt templates | front-matter parsing, quoted values, `{{placeholder}}` rendering, missing values |
| Prompt files | every `PromptID` loads from the bundle and renders completely |
| Match data | goals match the score, scorers are in the right squad, events in time order |
| Match summary | decoding (incl. Markdown fences), validation, view model states |
| Smart search | filters against real data, chips, schema field names match the Swift type, AI → keyword fallback, removing chips |
| Chat | sending, streaming, Stop, failures, input limits, history window |
| Reliability | fallback for `complete` and `stream`, retry rules and backoff, latency reports |
| Error messages | every error type maps to a friendly message without technical details |

---

## Limitations

- **On-device fallback** requires a device where Apple Intelligence (Foundation Models) is available.
  Elsewhere it reports itself unavailable and the app shows a friendly error.
- **The API key ships inside the app** (Info.plist). Fine for a demo; a production app would call
  its own backend, which holds the key, rate-limits users and can change prompts remotely.
- **Match data is a bundled, fictional sample** using real club and player names. There is no live data, by design.

## Next steps

- An automated eval runner instead of manual runs
- A fake network layer (`URLProtocol`) to test the retry loop end to end
- Accessibility pass (VoiceOver with streaming text, Dynamic Type)
