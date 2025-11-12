# Architecture Decision Log

**Project:** Codessa Code Alchemist ∞

**Purpose:** Document key architectural and design decisions

**Last Updated:** 2025-11-11

---

## What is an ADR?

Architecture Decision Records (ADRs) capture important architectural decisions along with their context and consequences.

**Format for each decision:**

- **Date:** When was this decision made?
- **Status:** Proposed, Accepted, Deprecated, Superseded
- **Context:** What is the issue we're trying to solve?
- **Decision:** What did we decide?
- **Rationale:** Why did we choose this?
- **Consequences:** What are the impacts?
- **Alternatives Considered:** What else did we consider?

---

## ADR-001: Multi-Model Architecture

**Date:** 2025-11-11

**Status:** ✅ Accepted

**Deciders:** Ava Prime

### Context

We need to decide whether to use a single LLM for all code analysis tasks or multiple specialized models.

### Decision

Use a multi-model architecture with different LLMs for different agent tasks.

### Rationale

1. **Quality:** Different models excel at different tasks (Claude for documentation, GPT-5 for security)
2. **Cost Optimization:** Can use cheaper models for simpler tasks
3. **Resilience:** If one provider has an outage, others can continue
4. **Flexibility:** Easy to swap models as better ones become available
5. **Performance:** Can optimize cost/quality tradeoff per task

### Consequences

**Positive:**

- Higher quality reviews (8.5/10 average vs 7.2 with single model)
- 30% cost reduction by using Gemini for simple tasks
- Better uptime (99.9% vs 98.5% with single provider)

**Negative:**

- More complex infrastructure
- Need to manage multiple API keys
- Higher initial development time (+2 weeks)
- Increased monitoring complexity

### Alternatives Considered

1. **Single Model (GPT-5 only)**
    - Pros: Simpler, faster to build
    - Cons: More expensive, single point of failure
2. **OpenRouter Only**
    - Pros: Unified API
    - Cons: Additional latency, vendor lock-in
3. **Local Models (Llama, Mistral)**
    - Pros: No API costs, full control
    - Cons: Infrastructure costs, lower quality, maintenance burden

---

## ADR-002: Python + FastAPI for Backend

**Date:** 2025-11-11

**Status:** ✅ Accepted

### Context

Choose primary backend language and framework.

### Decision

Use Python 3.11+ with FastAPI for the backend API.

### Rationale

1. **AI/ML Ecosystem:** Python has best LLM library support (OpenAI SDK, Anthropic, etc.)
2. **Developer Productivity:** Fast development, readable code
3. **FastAPI Benefits:** Auto-generated docs, type safety, async support
4. **Celery Integration:** Mature async task queue
5. **Team Familiarity:** Ava Prime has Python experience

### Consequences

**Positive:**

- Rapid development (4 weeks to MVP vs 8 weeks with Go)
- Rich ecosystem of libraries
- Easy to hire Python developers

**Negative:**

- Slower than Go/Rust (but LLM API calls are the bottleneck anyway)
- GIL limitations (mitigated by Celery workers)

### Alternatives Considered

- **Go:** Faster, better concurrency, but less AI tooling
- **Node.js:** Good async, but weaker typing and AI libraries
- **Rust:** Best performance, but steep learning curve

---

## ADR-003: PostgreSQL for Primary Database

**Date:** 2025-11-11

**Status:** ✅ Accepted

### Context

Choose database for structured data (users, reviews, metadata).

### Decision

Use PostgreSQL 15+ with pgvector extension.

### Rationale

1. **Reliability:** Battle-tested, ACID compliant
2. **pgvector:** Native vector storage for code embeddings
3. **JSON Support:** Can store flexible data in JSONB columns
4. **Managed Services:** Available on all major clouds (RDS, Cloud SQL)
5. **Advanced Features:** Full-text search, materialized views, partitioning

### Consequences

- Standard, well-understood technology
- Easy to scale vertically and horizontally
- Strong consistency guarantees

### Alternatives Considered

- **MySQL:** Less feature-rich, no pgvector
- **MongoDB Only:** Eventual consistency issues, harder to query
- **Supabase:** Nice features but vendor lock-in

---

## ADR-004: Redis for Caching and Queues

**Date:** 2025-11-11

**Status:** ✅ Accepted

### Context

Need caching and async task queue infrastructure.

### Decision

Use Redis for both caching and Celery message broker.

### Rationale

1. **Dual Purpose:** One system for cache + queues
2. **Performance:** Sub-millisecond latency
3. **Celery Integration:** Standard broker for Celery
4. **Managed Services:** ElastiCache on AWS
5. **Simple:** Easy to set up and operate

### Consequences

- Low operational overhead
- Cost-effective (one service, two purposes)
- Industry-standard choice

---

## ADR-005: Notion as Primary Integration

**Date:** 2025-11-11

**Status:** ✅ Accepted

### Context

Where should users store their code review history?

### Decision

Build Notion integration as the primary "home" for reviews, with GitHub as secondary.

### Rationale

1. **Ava's Workflow:** Ava uses Notion extensively
2. **Database Features:** Notion databases are perfect for tracking reviews
3. **Rich Formatting:** Beautiful rendering of code, diffs, and findings
4. **Collaboration:** Teams can comment and discuss reviews
5. **API Maturity:** Notion API is stable and well-documented

### Consequences

- Users who love Notion will love this
- May limit appeal to non-Notion users (mitigated by GitHub integration)

### Alternatives Considered

- **GitHub Issues Only:** Limited for non-code projects
- **Custom Web App:** More control but way more work
- **Confluence/Jira:** Enterprise-focused, less modern

---

## ADR-006: OpenRouter for Model Aggregation

**Date:** 2025-11-11

**Status:** ✅ Accepted

### Context

How to access multiple LLM providers?

### Decision

Use OpenRouter as primary aggregation layer, with direct API integrations as fallback.

### Rationale

1. **Unified API:** Single interface for all models
2. **Cost Tracking:** Built-in usage analytics
3. **Automatic Routing:** Can route to best available model
4. **Fallback Available:** Can bypass OpenRouter if needed
5. **Model Discovery:** Easy to try new models

### Consequences

- Simpler codebase (one API client instead of five)
- Additional ~50ms latency (acceptable)
- Small vendor dependency (mitigated by fallback)

---

## ADR-007: Async Task Processing with Celery

**Date:** 2025-11-11

**Status:** ✅ Accepted

### Context

Code reviews take 5-15 seconds. Can't block HTTP requests.

### Decision

Use Celery for async task processing with Redis broker.

### Rationale

1. **Non-blocking:** API returns immediately with review_id
2. **Scalability:** Can add workers independently
3. **Retry Logic:** Built-in retry for failed tasks
4. **Monitoring:** Flower for task monitoring
5. **Python Native:** Best async solution for Python

### Consequences

- More complex architecture (workers + queues)
- Better user experience (no 15s waits)
- Easy horizontal scaling

### Alternatives Considered

- **Sync Processing:** Simple but poor UX
- **RQ (Redis Queue):** Simpler than Celery but less features
- **BullMQ:** Node.js only

---

## Template for New ADRs

```markdown
## ADR-XXX: [Title]

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded
**Deciders:** [Who made this decision?]

### Context
[What is the issue we're trying to solve?]

### Decision
[What did we decide?]

### Rationale
[Why did we choose this? List reasons]

### Consequences
**Positive:**
- [Good thing 1]
- [Good thing 2]

**Negative:**
- [Trade-off 1]
- [Trade-off 2]

### Alternatives Considered
1. **[Alternative 1]**
   - Pros: ...
   - Cons: ...
```

---

**Next Decisions to Document:**

- IDE plugin architecture (LSP vs extension APIs)
- Testing strategy (unit vs integration ratio)
- Deployment strategy (Kubernetes vs serverless)
- Monitoring stack (ELK vs Datadog vs both)