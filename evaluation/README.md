# Track B — Enemy-agent evaluation

**Owner:** Kadir Zongur (collaborates with Serhat on tools and safeguards).

This folder will contain the **at least 20 predefined evaluation scenarios/queries** required by COMP205, plus a reproducible evaluation runner and results. None exist yet.

Each scenario should specify sanitized battle state, available legal actions/tools, expected action or invariant, and what constitutes success/failure. Cover normal tactics, invalid arguments, empty options, timeouts, tool errors, prompt injection and inconsistent model responses.

Suggested eventual results: tool-selection accuracy, legal-action rate, state-transition validity, response latency, and representative failure cases. Compare the agent with a deterministic baseline where possible. **The battle engine validates and applies changes; never let LLM text mutate trusted game state directly.**
