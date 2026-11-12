# Learning notes: building LLM features in iOS

What I learned building this project, written as a reference for later and for interviews.

---

## 1. What an LLM is, practically

- A model that predicts the next piece of text (a **token**) given everything before it.
- It only understands **text**: data must be turned into text (e.g. JSON) to reach it.
- It has **no memory** between requests: a chat resends the whole conversation every time.
- It produces **likely** text, not guaranteed-correct text: output must be checked.
- It can be slow, overloaded, retired or unavailable: the app must cope.

## 2. The request (OpenAI-compatible Chat Completions)

Gemini, OpenAI, Groq and Ollama all accept this format, so one client works with all of them.

| Field | Meaning |
|---|---|
| `model` | which model answers, e.g. `gemini-flash-lite-latest` |
| `messages` | the conversation: `[{role, content}]`, roles `system`, `user`, `assistant` |
| `stream` | `true` = pieces as they're generated, `false` = one complete answer |
| `temperature` | randomness: low (0–0.3) for facts and JSON, higher for creative text |
| `response_format` | structured output: force JSON in a given schema |
| `max_tokens` | maximum answer length (a useful safety limit) |
| `top_p` | another randomness control; adjust either this or temperature |
| `stop` | text that ends the answer |
| `n` | number of alternative answers (`choices[0]`, `choices[1]`, …) |
| `tools`, `tool_choice` | let the model call your functions (the basis of agents) |

Structured output envelope (the schema goes one level down, under `schema`):

```json
"response_format": {
  "type": "json_schema",
  "json_schema": { "name": "response", "schema": { "type": "object", … } }
}
```

## 3. The response

| | `stream: true` | `stream: false` |
|---|---|---|
| Arrives as | many `data: {…}` lines (server-sent events), then `data: [DONE]` | one JSON object |
| Text is in | `choices[0].delta.content` (the **new** piece) | `choices[0].message.content` (the whole answer) |
| Use for | text a person reads (chat) | data code must process (JSON) |

- **SSE (server-sent events):** a web standard for a server pushing updates over one HTTP connection.
- `URLSession.bytes(for:)` gives bytes as they arrive (needed for streaming);
  `data(for:)` collects them all and returns the complete `Data`.
- Errors come back as normal JSON with an HTTP status, not as `data:` lines.

## 4. HTTP errors and what to do

| Status | Meaning | Action |
|---|---|---|
| 400 / 401 | bad request or bad key | don't retry; fix code or config |
| 404 | model retired or unavailable | try another model |
| 429 | rate limited | wait and retry, or try another model |
| 503 | provider overloaded | retry, then fall back |
| timeout | no data for `timeoutInterval` seconds | try another model |

`URLRequest.timeoutInterval` is the maximum time **without receiving data**, not the total duration.

## 5. Prompt design

A good system prompt has: **role & task**, **rules**, **output format**, **examples**, and **data** (clearly marked).

- Be specific and measurable: "under 15 words", not "short".
- Say what to do, not only what to avoid.
- Give a reason when a rule might seem odd.
- Cover the edge cases ("if little happened…", "if off-topic…").
- **Examples are copied closely:** they must follow your own rules, use made-up data,
  and should differ from your test inputs.
- Wrap data in tags (`<match_data>…</match_data>`) and say it's data, not instructions.
- Rules that conflict get dropped silently: fix the conflict instead of repeating the rule louder.
- Prompts are code: keep them in files, version them, log the version with every request.

## 6. Structured output: three layers

1. **Prompt** asks for the format and meaning.
2. **JSON Schema** (`response_format`) constrains the shape, including allowed values (`enum`).
3. **Code** decodes and validates the content (counts, lengths, facts against real data).

The schema guarantees shape, not content. Validation is the real guarantee.

## 7. Guardrails

Anything that keeps an AI feature within intended boundaries, in three places:
- **Before the model:** input limits, history window, marking user text as data.
- **In the prompt:** scope, no live data, no betting advice, ignore role changes.
- **After the model:** decoding, validation, never showing rejected output.

Never rely on the prompt alone: the prompt makes good behaviour likely, code makes bad output impossible to show.

## 8. Evals

- A fixed set of test inputs, run against every prompt version, results written down.
- Change one thing, rerun **everything**: a fix can break another case.
- Use **held-out** tests that don't match the prompt's examples, or you only test copying.
- Log the prompt version, so you know which prompt produced an answer
  (this caught a stale app bundle still using an old prompt).

## 9. Fallbacks

- **Model fallback:** try the next model on 404/429/503/timeout.
- **Provider fallback:** wrap providers (`FallbackLLMClient`) behind the same protocol.
- In a stream, only switch before any text is shown.
- Never fall back after the user cancels.
- If everything fails, show a friendly message; log the real error.

## 10. On-device AI (Apple Foundation Models)

- Free, private, offline; weaker than cloud models.
- Needs a supported device, a recent OS, Apple Intelligence enabled and models downloaded.
- `isAvailable == true` doesn't guarantee success (e.g. Apple's safety model failed to load).
- Streams **snapshots** (whole text so far), not deltas: convert them to match your interface.
- Availability depends on things outside your app, so it must always be optional.

## 11. iOS engineering lessons from this project

- Depend on protocols (`LLMProviding`), inject dependencies, keep a mock for tests, previews and demo mode.
- Keep a reusable layer (LLMKit) free of feature knowledge; the compiler then enforces boundaries.
- `.gitignore` doesn't affect files git already tracks: `git rm --cached` them.
- Secrets in `.xcconfig` + `#include?` let the project build without them. **No quotes** in xcconfig values.
- `Text("\(number)")` formats numbers by locale; use `Text(verbatim:)` for raw values.
- Swift Testing: parameterized tests (`@Test(arguments:)`, `zip` for input/output pairs),
  `#expect(throws:)`, `#require`, `Issue.record`.
- A test that can't fail when the code is wrong is worse than no test.
