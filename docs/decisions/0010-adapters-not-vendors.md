# 10. The model layer speaks adapters, not vendors

**Date:** 2026-07-25
**Status:** Accepted

## Context

The classifier called the Anthropic SDK directly. Adding OpenAI and Gemini to
the registry would have let an admin certify — that is, vouch for — a model the
code could not call, which is the registry claiming a capability it does not
have. That is the failure this project exists to catch, occurring inside its own
plumbing.

## Decisions

### Every provider is reached through an adapter

`LlmClients::Base` defines one method: `complete(system:, user:, schema:,
max_tokens:)` returning a `Completion`. The classifier and the proposer speak
only that. Which vendor answers is resolved from the registry, so it is a
governed decision rather than a fact about the code.

### A provider needs an adapter *and* a credential, and these fail differently

- **Adapter** — can this code call it at all? `LlmProvider#invocable?`.
  `LlmModel` refuses certification without one.
- **Credential** — may it? Stored encrypted or read from the environment.

A provider with no adapter may still be registered. Listing is bookkeeping;
certifying is a claim about capability, and only the second is refused.

### Failure is reported in one taxonomy

```
CallFailed
├── Retryable
│   ├── RateLimited        429
│   ├── ServerError        5xx
│   └── ConnectionFailed   timeouts, resets
├── RequestRejected        4xx — retrying reaches the same answer
└── ResponseTruncated      cut off at the token limit
```

The decision that depends on this — wait, or stop — is the same whoever was
called. The previous retry rule named `Anthropic::Errors::RateLimitError`, so a
Gemini 429 fell straight through and stopped the run: a rule that read like a
retry policy and was one only for the provider wired up first.

### A truncated answer is never returned as an answer

Gemini charges its thinking against `maxOutputTokens`. One call spent 3,830
tokens of a 4,096 budget thinking and 251 writing, and the JSON stopped
mid-object. The adapter returned it as a `Completion`, the parser read half a
document as an empty one, and the run recorded a **successful call that produced
no judgements**. `finishReason` is now checked, and truncation raises.

`ResponseTruncated` is deliberately not `Retryable`: the same request is cut off
in the same place.

### One call may produce many judgements

`LlmInvocation belongs_to :assertion` was true only while calls carried a single
claim. Batching made it false, and a false audit link is worse than a coarse
one. The link moved to the assertion side, where it can be many.

## Rejected

**Keep the vendor SDK's error classes and branch on provider.** Every caller
would then have to know which vendor it was talking to, which is exactly the
coupling the registry exists to remove — and it fails silently, by not
retrying, rather than loudly.

**A fallback to the cheapest certified model when no rule matches.** A call
would silently run on a model nobody chose for it, and the invocation record
would be the only place that fact appeared.

## Consequences

Adding a provider is an adapter plus a registry row. The Anthropic and Gemini
adapters have been exercised against live APIs; OpenAI has not, and is seeded
uncertified — certification is where a person puts their name to "this works".
