# Technical Architecture Documentation

# Overview

This document provides comprehensive technical architecture documentation for the Codessa Code Alchemist system, covering all major components, interactions, data flows, and implementation guidelines.

**Document Version:** 1.0.0

**Last Updated:** 2025-11-11

**Owner:** Ava Prime

**Status:** Draft

---

# 1. System Components & Responsibilities

## 1.1 Core Components

### Router / Orchestrator Service

**Responsibility:** Central coordination layer that receives code input, determines optimal processing strategy, and orchestrates multi-agent workflows.

**Key Functions:**

- Request intake and validation
- Language detection and metadata extraction
- Agent selection based on code characteristics and user preferences
- Parallel task distribution and result aggregation
- Response formatting and delivery

**Technology Stack:**

- **Phase 0:** N/A (handled by Gemini prompt logic)
- **Phase 1+:** Python 3.11+ with FastAPI 0.104+
- **Message Queue:** Redis 7.2+ for task distribution
- **Process Management:** Celery 5.3+ for async task execution

**Scaling Considerations:**

- Horizontally scalable behind load balancer
- Stateless design for easy replication
- Connection pooling for external APIs

---

### Analysis Agents

**Responsibility:** Specialized AI-powered agents that perform specific code analysis tasks.

### Agent Types:

**Syntax & Formatting Agent**

- Detects language and framework
- Validates syntax correctness
- Checks code style compliance
- Suggests formatting improvements
- **Models:** GPT-5, Claude Sonnet

**Code Review Agent**

- Analyzes readability and structure
- Identifies naming issues
- Detects code smells
- Suggests refactoring patterns
- **Models:** Claude Code, GPT-5

**Security Auditor Agent**

- Scans for vulnerabilities (OWASP Top 10)
- Detects secrets and credentials
- Checks dependency security
- Validates input sanitization
- **Models:** GPT-5, Grok, Claude Opus

**Performance Analyzer Agent**

- Calculates algorithmic complexity
- Identifies bottlenecks
- Suggests optimization strategies
- Estimates resource usage
- **Models:** Gemini 1.5, GPT-5

**Test Generator Agent**

- Creates unit tests
- Generates integration tests
- Produces test data fixtures
- Suggests edge cases
- **Models:** GPT-5, Gemini 2.5

**Documentation Agent**

- Generates docstrings
- Creates inline comments
- Writes README sections
- Produces API documentation
- **Models:** Claude Sonnet, GPT-5

**Technical Implementation:**

- Each agent is a Python class implementing `BaseAgent` interface
- Agents communicate via standardized JSON schema
- Configurable model selection per agent
- Fallback models for redundancy

---

### Rating & Aggregation Engine

**Responsibility:** Consolidates outputs from multiple agents, resolves conflicts, and produces unified recommendations.

**Key Functions:**

- Result merging and deduplication
- Confidence score calculation
- Conflict resolution (when agents disagree)
- Quality score computation across 6 dimensions
- Priority ranking of suggestions

**Algorithms:**

- **Weighted voting:** Higher-confidence suggestions weighted more heavily
- **Consensus detection:** Identify agreements across multiple agents
- **Outlier filtering:** Flag and review anomalous suggestions
- **Score normalization:** Standardize ratings across different models

**Technology:**

- Python with NumPy/Pandas for numerical operations
- Custom scoring algorithms
- Configurable weighting system

---

### Model Gateway / LLM Abstraction Layer

**Responsibility:** Unified interface for interacting with multiple AI model providers.

**Key Functions:**

- API key management and rotation
- Request routing to appropriate model endpoints
- Response parsing and normalization
- Rate limiting and quota management
- Retry logic with exponential backoff
- Cost tracking and optimization

**Supported Providers:**

- OpenAI (GPT-5, GPT-4)
- Anthropic (Claude Opus, Sonnet, Haiku)
- Google (Gemini 1.5, 2.0)
- xAI (Grok)
- OpenRouter (aggregated access)

**Technology:**

- LiteLLM or custom abstraction layer
- Environment-based configuration
- Circuit breaker pattern for fault tolerance

---

### Data Storage Layer

**Responsibility:** Persist code artifacts, review history, and system metadata.

### Storage Types:

**Relational Database (PostgreSQL 15+)**

- User accounts and authentication
- Review metadata and status
- Agent performance metrics
- Audit logs

**Document Store (MongoDB 7+ or Notion API)**

- Code review history
- Full code artifacts (original + refined)
- Diff snapshots
- JSON manifests

**Cache Layer (Redis 7.2+)**

- Session data
- Frequently accessed reviews
- Rate limiting counters
- Temporary job status

**Object Storage (S3-compatible)**

- Large code files
- Generated test files
- Documentation artifacts
- Backup archives

**Vector Database (Pinecone, Weaviate, or pgvector)**

- Code embeddings for similarity search
- Pattern recognition
- Recommendation engine data

---

### Integration Connectors

**Responsibility:** Interface with external systems and platforms.

**Notion Connector**

- Writes review results to databases
- Creates new pages for artifacts
- Updates existing documentation
- **API:** Notion REST API v1

**GitHub Connector**

- Posts PR comments
- Creates issues for findings
- Generates commit messages
- **API:** GitHub REST API v3 + GraphQL

**IDE Extensions**

- VSCode/Cursor plugin
- Real-time code analysis
- Inline suggestion display
- **Protocol:** Language Server Protocol (LSP)

**CI/CD Integration**

- GitHub Actions
- GitLab CI
- Jenkins webhooks
- **Interface:** Webhook receivers + REST API

---

### Authentication & Authorization Service

**Responsibility:** Manage user identity, access control, and API authentication.

**Key Functions:**

- User registration and login
- API key generation and validation
- Role-based access control (RBAC)
- OAuth integration
- Session management

**Technology:**

- Auth0, Clerk, or custom JWT-based system
- OAuth 2.0 / OpenID Connect
- API key hashing with bcrypt

---

### Monitoring & Observability Stack

**Responsibility:** Track system health, performance, and usage analytics.

**Components:**

- **Metrics:** Prometheus + Grafana
- **Logs:** ELK Stack (Elasticsearch, Logstash, Kibana) or Loki
- **Traces:** OpenTelemetry + Jaeger
- **Alerting:** PagerDuty or Opsgenie
- **APM:** Datadog or New Relic

**Key Metrics:**

- Request latency (p50, p95, p99)
- Error rates by component
- Model API costs
- Agent success rates
- User satisfaction scores

---

# 2. Communication Protocols & APIs

## 2.1 External API (Client-Facing)

### REST API Specification

**Base URL:** [`https://api.codealchemist.dev/v1`](https://api.codealchemist.dev/v1)

**Authentication:** Bearer token in `Authorization` header

### Endpoint: Submit Code for Review

```
POST /reviews
Content-Type: application/json
Authorization: Bearer {api_key}

{
  "code": "def hello():\n    print('Hello')",
  "language": "python",  // optional, auto-detected if omitted
  "filename": "[hello.py](http://hello.py)",  // optional
  "context": "This is a greeting function",  // optional
  "improvements": ["readability", "tests", "docs"],  // optional
  "async": false  // if true, returns job_id for polling
}

Response 200 OK:
{
  "review_id": "rev_abc123",
  "status": "completed",
  "language": "python",
  "findings": [
    {
      "severity": "medium",
      "category": "documentation",
      "message": "Function lacks docstring",
      "line": 1,
      "suggestion": "Add docstring describing purpose"
    }
  ],
  "scores": {
    "correctness": 9.0,
    "readability": 7.5,
    "security": 10.0,
    "performance": 8.0,
    "testability": 4.0,
    "maintainability": 6.5
  },
  "refined_code": "def hello():\n    \"\"\"Print a greeting message.\"\"\"\n    print('Hello')",
  "diff": "@@ -1,2 +1,3 @@\n def hello():\n+    \"\"\"Print a greeting message.\"\"\"\n     print('Hello')",
  "tests": "def test_hello(capsys):\n    hello()\n    captured = capsys.readouterr()\n    assert captured.out == 'Hello\\n'",
  "manifest": {
    "models_used": ["gpt-5", "claude-sonnet"],
    "processing_time_ms": 2341,
    "cost_usd": 0.023
  }
}
```

### Endpoint: Get Review Status

```
GET /reviews/{review_id}
Authorization: Bearer {api_key}

Response 200 OK:
{
  "review_id": "rev_abc123",
  "status": "completed",  // or "pending", "processing", "failed"
  "created_at": "2025-11-11T18:30:00Z",
  "completed_at": "2025-11-11T18:30:02Z",
  // ... full review data if completed
}
```

### Endpoint: List User Reviews

```
GET /reviews?limit=20&offset=0&status=completed
Authorization: Bearer {api_key}

Response 200 OK:
{
  "reviews": [...],
  "total": 156,
  "limit": 20,
  "offset": 0
}
```

---

## 2.2 Internal Communication

### Message Queue Protocol (Redis/Celery)

**Task Structure:**

```python
{
  "task_id": "task_xyz789",
  "task_type": "code_review",
  "priority": "normal",  // or "high", "low"
  "payload": {
    "review_id": "rev_abc123",
    "code": "...",
    "language": "python",
    "agents": ["security", "readability", "tests"]
  },
  "metadata": {
    "user_id": "user_123",
    "timestamp": "2025-11-11T18:30:00Z"
  }
}
```

**Queue Names:**

- `code_alchemist:reviews:high` - Priority reviews
- `code_alchemist:reviews:normal` - Standard queue
- `code_alchemist:reviews:low` - Background processing
- `code_alchemist:agent:{agent_name}` - Agent-specific queues

---

### Agent Communication Schema

**Request to Agent:**

```json
{
  "agent_request_id": "agt_req_456",
  "code": "function code here",
  "language": "python",
  "context": {
    "filename": "[hello.py](http://hello.py)",
    "framework": "fastapi",
    "user_preferences": {}
  },
  "instruction": "Analyze for security vulnerabilities"
}
```

**Response from Agent:**

```json
{
  "agent_request_id": "agt_req_456",
  "agent_name": "security_auditor",
  "model_used": "gpt-5",
  "status": "success",
  "confidence": 0.92,
  "findings": [
    {
      "type": "vulnerability",
      "severity": "high",
      "line": 42,
      "message": "SQL injection risk",
      "explanation": "...",
      "suggestion": "Use parameterized queries",
      "confidence": 0.95
    }
  ],
  "score": 6.5,
  "processing_time_ms": 1234
}
```

---

### Model Gateway API (Internal)

**Abstraction Interface:**

```python
class ModelGateway:
    def complete(
        self,
        model: str,  # "gpt-5", "claude-opus", etc.
        messages: List[Message],
        temperature: float = 0.7,
        max_tokens: int = 4000,
        timeout: int = 30
    ) -> ModelResponse:
        # Returns normalized response across all providers
        pass
```

**Response Format:**

```json
{
  "content": "Model response text",
  "model": "gpt-5",
  "usage": {
    "prompt_tokens": 1234,
    "completion_tokens": 567,
    "total_tokens": 1801
  },
  "cost_usd": 0.018,
  "latency_ms": 2341
}
```

---

# 3. Data Storage & Persistence

## 3.1 Database Schema (PostgreSQL)

### Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),
    password_hash VARCHAR(255),  -- bcrypt hash
    api_key_hash VARCHAR(255) UNIQUE,
    tier VARCHAR(50) DEFAULT 'free',  -- free, pro, enterprise
    created_at TIMESTAMP DEFAULT NOW(),
    last_login_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    preferences JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_api_key ON users(api_key_hash);
```

### Reviews Table

```sql
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,  -- pending, processing, completed, failed
    language VARCHAR(50),
    original_code TEXT NOT NULL,
    refined_code TEXT,
    diff TEXT,
    findings JSONB,
    scores JSONB,
    manifest JSONB,
    created_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    error_message TEXT
);

CREATE INDEX idx_reviews_user_id ON reviews(user_id);
CREATE INDEX idx_reviews_status ON reviews(status);
CREATE INDEX idx_reviews_created_at ON reviews(created_at DESC);
```

### Agent Executions Table

```sql
CREATE TABLE agent_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID REFERENCES reviews(id) ON DELETE CASCADE,
    agent_name VARCHAR(100) NOT NULL,
    model_used VARCHAR(100),
    status VARCHAR(50) NOT NULL,
    confidence DECIMAL(3,2),
    findings JSONB,
    processing_time_ms INTEGER,
    cost_usd DECIMAL(10,6),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_agent_executions_review_id ON agent_executions(review_id);
CREATE INDEX idx_agent_executions_agent_name ON agent_executions(agent_name);
```

### Audit Logs Table

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
```

---

## 3.2 Document Storage (MongoDB)

### Reviews Collection

```jsx
{
  _id: ObjectId("..."),
  review_id: "rev_abc123",
  user_id: "user_123",
  code_artifacts: {
    original: "...",
    refined: "...",
    tests: "...",
    documentation: "..."
  },
  metadata: {
    filename: "[example.py](http://example.py)",
    language: "python",
    framework: "fastapi",
    file_size_bytes: 1234
  },
  analysis: {
    findings: [...],
    scores: {...},
    agent_outputs: [...]
  },
  versions: [  // Track iterations
    {
      version: 1,
      timestamp: ISODate("..."),
      changes: "Initial review"
    }
  ],
  created_at: ISODate("..."),
  updated_at: ISODate("...")
}
```

**Indexes:**

```jsx
[db.reviews](http://db.reviews).createIndex({ "review_id": 1 }, { unique: true });
[db.reviews](http://db.reviews).createIndex({ "user_id": 1, "created_at": -1 });
[db.reviews](http://db.reviews).createIndex({ "metadata.language": 1 });
```

---

## 3.3 Cache Strategy (Redis)

### Key Patterns:

```
review:{review_id}                 # Full review data (TTL: 1 hour)
user:{user_id}:session             # User session (TTL: 24 hours)
ratelimit:{user_id}:{endpoint}     # Rate limit counter (TTL: 1 minute)
model:cost:{model_name}            # Current model pricing (TTL: 1 day)
code:embedding:{hash}              # Code embeddings (TTL: 7 days)
```

### Example Operations:

```python
# Cache review result
redis.setex(
    f"review:{review_id}",
    3600,  # 1 hour TTL
    json.dumps(review_data)
)

# Rate limiting
pipe = redis.pipeline()
pipe.incr(f"ratelimit:{user_id}:reviews")
pipe.expire(f"ratelimit:{user_id}:reviews", 60)
count, _ = pipe.execute()
if count[0] > RATE_LIMIT:
    raise RateLimitExceeded()
```

---

## 3.4 Vector Storage (pgvector)

### Code Embeddings Table

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE code_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code_hash VARCHAR(64) UNIQUE NOT NULL,  -- SHA-256 of code
    language VARCHAR(50),
    embedding vector(1536),  -- OpenAI ada-002 dimension
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX ON code_embeddings USING ivfflat (embedding vector_cosine_ops)
    WITH (lists = 100);
```

### Similarity Search:

```sql
SELECT code_hash, language, metadata, 1 - (embedding <=> $1) AS similarity
FROM code_embeddings
WHERE language = $2
ORDER BY embedding <=> $1
LIMIT 10;
```

---

# 4. Security Architecture

## 4.1 Authentication Flows

### User Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant AuthService
    participant Database
    
    User->>Frontend: Enter credentials
    Frontend->>AuthService: POST /auth/login
    AuthService->>Database: Verify credentials
    Database-->>AuthService: User data
    AuthService->>AuthService: Generate JWT
    AuthService-->>Frontend: JWT + Refresh Token
    Frontend->>Frontend: Store tokens (httpOnly cookie)
    Frontend-->>User: Login successful
```

### API Key Authentication

```mermaid
sequenceDiagram
    participant Client
    participant Gateway
    participant AuthService
    participant Cache
    
    Client->>Gateway: Request + API Key
    Gateway->>Cache: Check key cache
    alt Key in cache
        Cache-->>Gateway: User ID
    else Key not cached
        Gateway->>AuthService: Validate key
        AuthService-->>Gateway: User ID
        Gateway->>Cache: Cache key->user mapping
    end
    Gateway->>Gateway: Process request
    Gateway-->>Client: Response
```

---

## 4.2 Authorization Model

### Role-Based Access Control (RBAC)

**Roles:**

- `free_user`: 50 reviews/month, basic features
- `pro_user`: 1000 reviews/month, advanced features
- `enterprise_user`: Unlimited reviews, all features
- `admin`: System administration

**Permissions:**

```python
PERMISSIONS = {
    "free_user": [
        "review:create",
        "review:read:own",
        "review:delete:own"
    ],
    "pro_user": [
        "review:create",
        "review:read:own",
        "review:delete:own",
        "review:export",
        "integration:notion",
        "integration:github"
    ],
    "enterprise_user": [
        "*"  # All permissions
    ],
    "admin": [
        "*",
        "user:manage",
        "system:configure"
    ]
}
```

---

## 4.3 Data Security

### Encryption

**At Rest:**

- Database: PostgreSQL with transparent data encryption (TDE)
- Files: S3 server-side encryption (SSE-S3 or SSE-KMS)
- Backups: Encrypted with AES-256

**In Transit:**

- TLS 1.3 for all HTTP communications
- Certificate pinning for mobile apps
- Mutual TLS (mTLS) for inter-service communication (optional)

### Secrets Management

- AWS Secrets Manager or HashiCorp Vault
- API keys rotated every 90 days
- Model API keys stored in vault, never in code
- Environment-specific secrets isolation

---

## 4.4 Security Boundaries

```mermaid
graph TB
    Internet[Internet]
    
    subgraph "DMZ"
        LB[Load Balancer]
        WAF[Web Application Firewall]
    end
    
    subgraph "Application Layer"
        API[API Gateway]
        Auth[Auth Service]
        Router[Orchestrator]
    end
    
    subgraph "Processing Layer - Isolated"
        Agents[Agent Workers]
        Queue[Message Queue]
    end
    
    subgraph "Data Layer - Private Subnet"
        DB[(Database)]
        Cache[(Cache)]
        Storage[(Object Storage)]
    end
    
    subgraph "External Services - Egress Only"
        OpenAI[OpenAI API]
        Anthropic[Anthropic API]
        Google[Google AI API]
    end
    
    Internet --> WAF
    WAF --> LB
    LB --> API
    API --> Auth
    API --> Router
    Router --> Queue
    Queue --> Agents
    Agents --> DB
    Agents --> Cache
    Agents --> Storage
    Agents --> OpenAI
    Agents --> Anthropic
    Agents --> Google
```

---

## 4.5 Security Best Practices

### Input Validation

```python
from pydantic import BaseModel, validator

class CodeReviewRequest(BaseModel):
    code: str
    language: Optional[str] = None
    
    @validator('code')
    def validate_code_length(cls, v):
        if len(v) > 500_000:  # 500KB max
            raise ValueError('Code too large')
        if len(v) < 10:
            raise ValueError('Code too short')
        return v
    
    @validator('language')
    def validate_language(cls, v):
        ALLOWED = ['python', 'javascript', 'typescript', 'java', 'go', 'rust']
        if v and v.lower() not in ALLOWED:
            raise ValueError(f'Unsupported language: {v}')
        return v.lower() if v else None
```

### SQL Injection Prevention

- Always use parameterized queries
- Never concatenate user input into SQL
- Use ORM (SQLAlchemy) with bound parameters

### Rate Limiting

```python
# Per-user rate limits
RATELIMITS = {
    "free_user": {"reviews": "50/month", "api_calls": "100/hour"},
    "pro_user": {"reviews": "1000/month", "api_calls": "1000/hour"},
    "enterprise_user": {"reviews": "unlimited", "api_calls": "10000/hour"}
}
```

### Content Security

- Sanitize code before sending to LLMs (remove secrets)
- Don't log user code in plain text
- Implement data retention policies (delete after N days)

---

# 5. Performance & Scaling

## 5.1 Performance Targets

| Metric | Target | Measurement |
| --- | --- | --- |
| API Response (simple review) | < 5s p95 | End-to-end latency |
| API Response (multi-agent) | < 15s p95 | End-to-end latency |
| Throughput | 100 req/s | Sustained load |
| Database query time | < 100ms p95 | Individual queries |
| Cache hit rate | > 80% | Review lookups |
| Model API latency | < 3s p95 | LLM response time |

---

## 5.2 Scaling Strategies

### Horizontal Scaling

**Stateless Components:**

- API Gateway: Scale to N replicas based on CPU/memory
- Orchestrator: Auto-scale based on queue depth
- Agent Workers: Scale per agent type based on queue length

**Kubernetes Deployment:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-alchemist-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    spec:
      containers:
      - name: api
        image: code-alchemist/api:latest
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: code-alchemist-api
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

---

### Database Scaling

**PostgreSQL:**

- **Read Replicas:** 2+ replicas for read queries
- **Connection Pooling:** PgBouncer (1000 max connections)
- **Partitioning:** Partition `reviews` table by created_at (monthly)
- **Vertical Scaling:** Start with 4 vCPU, 16GB RAM, scale to 32 vCPU, 128GB

**MongoDB:**

- **Sharding:** Shard by `user_id` for horizontal distribution
- **Replica Set:** 3-node replica set (1 primary, 2 secondaries)
- **Index Optimization:** Cover queries with compound indexes

**Redis:**

- **Cluster Mode:** 3+ master nodes with replication
- **Memory:** Start with 8GB, scale to 128GB
- **Eviction Policy:** `allkeys-lru` for cache data

---

### Caching Strategy

**Multi-Layer Caching:**

1. **Application-Level (In-Memory):**
    - User preferences: 5-minute TTL
    - Model pricing: 1-hour TTL
    - LRU cache, 1000 items max
2. **Distributed Cache (Redis):**
    - Review results: 1-hour TTL
    - Code embeddings: 7-day TTL
    - Session data: 24-hour TTL
3. **CDN (CloudFront/Cloudflare):**
    - Static assets: 1-year TTL
    - Documentation: 1-day TTL

---

### Asynchronous Processing

**Queue-Based Architecture:**

```python
# Fast API response
@[app.post](http://app.post)("/reviews")
async def create_review(request: CodeReviewRequest):
    # Quickly validate and enqueue
    review_id = generate_id()
    task = {
        "review_id": review_id,
        "code": request.code,
        "user_id": current_[user.id](http://user.id)
    }
    
    # Enqueue for async processing
    await queue.enqueue("code_review", task)
    
    # Return immediately
    return {
        "review_id": review_id,
        "status": "pending",
        "estimated_completion": "10 seconds"
    }
```

---

## 5.3 Performance Optimization Techniques

### Database Optimizations

```sql
-- Materialized view for user statistics
CREATE MATERIALIZED VIEW user_stats AS
SELECT 
    user_id,
    COUNT(*) as total_reviews,
    AVG(EXTRACT(EPOCH FROM (completed_at - created_at))) as avg_time_seconds,
    AVG((scores->>'overall')::float) as avg_score
FROM reviews
WHERE status = 'completed'
GROUP BY user_id;

CREATE UNIQUE INDEX ON user_stats(user_id);

-- Refresh periodically
REFRESH MATERIALIZED VIEW CONCURRENTLY user_stats;
```

### Connection Pooling

```python
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,          # Core connections
    max_overflow=10,       # Additional connections under load
    pool_timeout=30,       # Wait for connection
    pool_recycle=3600,     # Recycle connections hourly
    pool_pre_ping=True     # Verify connection before use
)
```

### Batch Processing

```python
# Process multiple agent requests in parallel
async def process_review_parallel(review_id: str, code: str):
    agents = ['security', 'readability', 'performance', 'tests']
    
    # Create tasks for all agents
    tasks = [
        call_agent(agent, code)
        for agent in agents
    ]
    
    # Execute in parallel
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Aggregate results
    return aggregate_agent_results(results)
```

---

# 6. Error Handling & Recovery

## 6.1 Error Classification

### Error Levels

```python
class ErrorLevel(Enum):
    INFO = "info"           # Informational, no action needed
    WARNING = "warning"     # Non-critical issue, system continues
    ERROR = "error"         # Operation failed, user notified
    CRITICAL = "critical"   # System component failed, needs immediate attention
```

### Error Categories

```python
class ErrorCategory(Enum):
    # User-caused errors (4xx)
    VALIDATION = "validation_error"           # Invalid input
    AUTHENTICATION = "authentication_error"   # Auth failed
    AUTHORIZATION = "authorization_error"     # Permission denied
    RATE_LIMIT = "rate_limit_exceeded"       # Too many requests
    NOT_FOUND = "not_found"                  # Resource doesn't exist
    
    # System errors (5xx)
    MODEL_API = "model_api_error"            # LLM API failed
    DATABASE = "database_error"              # DB operation failed
    TIMEOUT = "timeout_error"                # Operation timed out
    INTERNAL = "internal_error"              # Unexpected error
```

---

## 6.2 Error Handling Patterns

### Retry with Exponential Backoff

```python
import asyncio
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type
)

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    retry=retry_if_exception_type((RequestException, Timeout))
)
async def call_model_api(prompt: str, model: str):
    """Call LLM API with automatic retry on transient failures."""
    try:
        response = await model_client.complete(model, prompt)
        return response
    except RateLimitError as e:
        # Don't retry on rate limits
        raise
    except APIError as e:
        # Log and retry
        logger.warning(f"API error, will retry: {e}")
        raise
```

### Circuit Breaker Pattern

```python
from circuitbreaker import circuit

@circuit(failure_threshold=5, recovery_timeout=60)
def call_external_service(url: str):
    """Circuit breaker prevents cascade failures.
    
    If 5 failures occur, circuit opens for 60 seconds.
    During open state, calls fail fast without hitting service.
    """
    response = requests.get(url, timeout=5)
    response.raise_for_status()
    return response.json()
```

### Fallback Strategies

```python
async def get_code_review_with_fallback(code: str) -> ReviewResult:
    """Try primary model, fall back to secondary on failure."""
    
    try:
        # Try primary model (GPT-5)
        result = await call_model_api(code, "gpt-5")
        return result
    except ModelAPIError:
        logger.warning("GPT-5 failed, falling back to Claude")
        
        try:
            # Fallback to Claude
            result = await call_model_api(code, "claude-opus")
            return result
        except ModelAPIError:
            logger.error("Both models failed, using cached generic review")
            
            # Final fallback: basic static analysis
            return static_code_analysis(code)
```

---

## 6.3 Error Response Format

### API Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Code length exceeds maximum allowed size",
    "details": {
      "field": "code",
      "max_length": 500000,
      "actual_length": 750000
    },
    "request_id": "req_xyz789",
    "timestamp": "2025-11-11T18:30:00Z",
    "documentation_url": "[https://docs.codealchemist.dev/errors/validation](https://docs.codealchemist.dev/errors/validation)"
  }
}
```

---

## 6.4 Monitoring & Alerting

### Error Tracking

```python
import sentry_sdk

sentry_sdk.init(
    dsn="https://...",
    traces_sample_rate=0.1,  # 10% of transactions
    profiles_sample_rate=0.1,
    environment="production"
)

# Automatic error capture
try:
    result = process_review(code)
except Exception as e:
    # Sentry automatically captures
    sentry_sdk.capture_exception(e)
    raise
```

### Alert Rules

```yaml
alerts:
  - name: high_error_rate
    condition: error_rate > 5%
    window: 5m
    severity: critical
    notify: [pagerduty, slack]
    
  - name: model_api_failures
    condition: model_api_error_count > 10
    window: 1m
    severity: high
    notify: [slack]
    
  - name: database_slow_queries
    condition: p95_query_time > 1s
    window: 10m
    severity: warning
    notify: [slack]
```

---

## 6.5 Data Recovery

### Backup Strategy

```yaml
backups:
  postgresql:
    method: pg_dump + WAL archiving
    frequency: 
      full: daily at 02:00 UTC
      incremental: continuous (WAL)
    retention: 
      daily: 7 days
      weekly: 4 weeks
      monthly: 12 months
    storage: S3 with versioning
    encryption: AES-256
    
  mongodb:
    method: mongodump
    frequency: daily at 03:00 UTC
    retention: 30 days
    storage: S3
    
  redis:
    method: RDB snapshots
    frequency: hourly
    retention: 24 hours
    note: "Ephemeral data, minimal backup needed"
```

### Disaster Recovery

```python
# Recovery Point Objective (RPO): 1 hour
# Recovery Time Objective (RTO): 4 hours

# Automated recovery script
def restore_from_backup(backup_timestamp: datetime):
    """Restore system from backup."""
    
    # 1. Restore database
    restore_postgresql(backup_timestamp)
    restore_mongodb(backup_timestamp)
    
    # 2. Verify data integrity
    verify_data_consistency()
    
    # 3. Rebuild caches
    warm_redis_cache()
    
    # 4. Run smoke tests
    run_health_checks()
    
    # 5. Enable traffic
    enable_load_balancer()
```

---

# 7. Deployment & Infrastructure

## 7.1 Deployment Topology

### Multi-Region Architecture (Production)

```mermaid
graph TB
    subgraph "Global"
        DNS[Route 53 / CloudFlare DNS]
        CDN[CloudFront CDN]
    end
    
    subgraph "Region: us-east-1"
        LB1[ALB]
        subgraph "EKS Cluster 1"
            API1[API Pods]
            Worker1[Agent Workers]
        end
        RDS1[(RDS Primary)]
        Redis1[(ElastiCache)]
    end
    
    subgraph "Region: eu-west-1"
        LB2[ALB]
        subgraph "EKS Cluster 2"
            API2[API Pods]
            Worker2[Agent Workers]
        end
        RDS2[(RDS Read Replica)]
        Redis2[(ElastiCache)]
    end
    
    DNS --> CDN
    CDN --> LB1
    CDN --> LB2
    LB1 --> API1
    API1 --> Worker1
    Worker1 --> RDS1
    Worker1 --> Redis1
    LB2 --> API2
    API2 --> Worker2
    Worker2 --> RDS2
    Worker2 --> Redis2
    RDS1 -.replication.-> RDS2
```

---

## 7.2 Infrastructure Requirements

### Environment Specifications

### Development

```yaml
environment: development
cloud_provider: AWS / Local (Docker Compose)

compute:
  api:
    type: t3.small
    count: 1
    cpu: 2 vCPU
    memory: 2 GB
  workers:
    type: t3.small
    count: 2
    cpu: 2 vCPU
    memory: 2 GB

database:
  postgresql:
    type: db.t3.micro
    storage: 20 GB
  mongodb:
    type: t3.small
    storage: 20 GB
  redis:
    type: cache.t3.micro
    memory: 1 GB

network:
  vpc: Single VPC
  subnets: Public only
  load_balancer: false
```

### Staging

```yaml
environment: staging
cloud_provider: AWS

compute:
  api:
    type: t3.medium
    count: 2
    cpu: 2 vCPU
    memory: 4 GB
  workers:
    type: t3.medium
    count: 4
    cpu: 2 vCPU
    memory: 4 GB

database:
  postgresql:
    type: db.t3.small
    storage: 100 GB
    multi_az: false
  mongodb:
    type: t3.medium
    storage: 100 GB
  redis:
    type: cache.t3.small
    memory: 2 GB

network:
  vpc: Dedicated VPC
  subnets: Public + Private
  load_balancer: ALB
```

### Production

```yaml
environment: production
cloud_provider: AWS
regions: [us-east-1, eu-west-1]

compute:
  api:
    type: t3.large
    min_count: 3
    max_count: 20
    cpu: 2 vCPU
    memory: 8 GB
  workers:
    type: c5.2xlarge  # Compute-optimized
    min_count: 5
    max_count: 50
    cpu: 8 vCPU
    memory: 16 GB

database:
  postgresql:
    type: db.r5.2xlarge  # Memory-optimized
    storage: 500 GB SSD
    multi_az: true
    read_replicas: 2
  mongodb:
    type: r5.xlarge
    storage: 1 TB SSD
    replica_set: 3 nodes
  redis:
    type: cache.r5.large
    memory: 16 GB
    cluster_mode: enabled
    shards: 3

network:
  vpc: Multi-VPC (per region)
  subnets: Public + Private + Database
  load_balancer: ALB with WAF
  cdn: CloudFront
  
monitoring:
  - CloudWatch
  - Datadog
  - Sentry
  
backup:
  automated: true
  retention: 30 days
```

---

## 7.3 Container Configuration

### Dockerfile (API Service)

```docker
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import requests; requests.get('[http://localhost:8000/health](http://localhost:8000/health)')"

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

### Docker Compose (Local Development)

```yaml
version: '3.8'

services:
  api:
    build: ./api
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgresql://user:pass@postgres:5432/codealchemist
      REDIS_URL: redis://redis:6379/0
      MONGODB_URL: mongodb://mongo:27017/codealchemist
    depends_on:
      - postgres
      - redis
      - mongo
    volumes:
      - ./api:/app
    command: uvicorn main:app --reload --host 0.0.0.0

  worker:
    build: ./worker
    environment:
      DATABASE_URL: postgresql://user:pass@postgres:5432/codealchemist
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - postgres
      - redis
    command: celery -A tasks worker --loglevel=info

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: codealchemist
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  mongo:
    image: mongo:7
    volumes:
      - mongo_data:/data/db
    ports:
      - "27017:27017"

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"

volumes:
  postgres_data:
  mongo_data:
  redis_data:
```

---

## 7.4 Kubernetes Manifests

### API Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-alchemist-api
  namespace: code-alchemist
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        version: v1
    spec:
      containers:
      - name: api
        image: codealchemist/api:1.0.0
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: url
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: llm-api-keys
              key: openai
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
  namespace: code-alchemist
spec:
  selector:
    app: api
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8000
  type: LoadBalancer
```

### Worker Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: code-alchemist-workers
  namespace: code-alchemist
spec:
  replicas: 5
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      containers:
      - name: worker
        image: codealchemist/worker:1.0.0
        env:
        - name: REDIS_URL
          value: redis://redis-service:6379/0
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: llm-api-keys
              key: openai
        resources:
          requests:
            memory: "1Gi"
            cpu: "1000m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        command: ["celery"]
        args: ["-A", "tasks", "worker", "--loglevel=info", "--concurrency=4"]
```

---

## 7.5 CI/CD Pipeline

### GitHub Actions Workflow

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install pytest pytest-cov
    
    - name: Run tests
      run: |
        pytest --cov=. --cov-report=xml
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
  
  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to Docker Hub
      uses: docker/login-action@v2
      with:
        username: $ secrets.DOCKER_USERNAME 
        password: $ secrets.DOCKER_TOKEN 
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: codealchemist/api:$ github.sha ,codealchemist/api:latest
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: $ [secrets.AWS](http://secrets.AWS)_ACCESS_KEY_ID 
        aws-secret-access-key: $ [secrets.AWS](http://secrets.AWS)_SECRET_ACCESS_KEY 
        aws-region: us-east-1
    
    - name: Deploy to EKS
      run: |
        aws eks update-kubeconfig --name code-alchemist-prod
        kubectl set image deployment/code-alchemist-api \
          api=codealchemist/api:$ github.sha 
        kubectl rollout status deployment/code-alchemist-api
```

---

## 7.6 Configuration Management

### Environment Variables

```bash
# .env.example

# Application
APP_ENV=production
LOG_LEVEL=INFO
DEBUG=false

# Database
DATABASE_URL=postgresql://user:[pass@localhost:5432](mailto:pass@localhost:5432)/codealchemist
MONGODB_URL=mongodb://[localhost:27017/codealchemist](http://localhost:27017/codealchemist)
REDIS_URL=redis://[localhost:6379/0](http://localhost:6379/0)

# LLM APIs
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_AI_API_KEY=AIza...
OPENROUTER_API_KEY=sk-or-...

# Integrations
NOTION_API_KEY=secret_...
GITHUB_TOKEN=ghp_...

# Security
JWT_SECRET=your-secret-key-here
API_KEY_SALT=your-salt-here

# Performance
MAX_WORKERS=10
QUEUE_MAX_SIZE=1000
REQUEST_TIMEOUT=30

# Monitoring
SENTRY_DSN=https://...@[sentry.io/](http://sentry.io/)...
DATADOG_API_KEY=...
```

### Secrets Management (AWS)

```bash
# Store secrets in AWS Secrets Manager
aws secretsmanager create-secret \
  --name code-alchemist/prod/database \
  --secret-string '{"username":"admin","password":"...","host":"..."}'

aws secretsmanager create-secret \
  --name code-alchemist/prod/llm-keys \
  --secret-string '{"openai":"sk-...","anthropic":"sk-ant-..."}'
```

---

## 7.7 Monitoring Setup

### Prometheus Configuration

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'code-alchemist-api'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - code-alchemist
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: api
      - source_labels: [__meta_kubernetes_pod_ip]
        action: replace
        target_label: __address__
        replacement: $1:8000

  - job_name: 'code-alchemist-workers'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names:
            - code-alchemist
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: worker
```

### Grafana Dashboard (JSON snippet)

```json
{
  "dashboard": {
    "title": "Code Alchemist - System Overview",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])"
          }
        ]
      },
      {
        "title": "Response Time p95",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
          }
        ]
      }
    ]
  }
}
```

---

**Document Status:** Draft - Ready for Technical Review

**Next Steps:** Architecture review meeting, infrastructure cost estimation, security audit

---

# 8. Cost Analysis & Budgeting

## 8.1 Infrastructure Cost Estimates

### Development Environment (Monthly)

```yaml
Compute:
  API (1x t3.small): $15
  Workers (2x t3.small): $30
Database:
  PostgreSQL (db.t3.micro): $12
  MongoDB (t3.small): $15
  Redis (cache.t3.micro): $12
Networking:
  Data transfer: $5
  
Total: ~$89/month
```

### Staging Environment (Monthly)

```yaml
Compute:
  API (2x t3.medium): $60
  Workers (4x t3.medium): $120
Database:
  PostgreSQL (db.t3.small): $25
  MongoDB (t3.medium): $30
  Redis (cache.t3.small): $25
Networking:
  ALB: $20
  Data transfer: $20
  
Total: ~$300/month
```

### Production Environment (Monthly)

```yaml
Compute:
  API (3-20x t3.large): $200-1,300
  Workers (5-50x c5.2xlarge): $730-7,300
Database:
  PostgreSQL (db.r5.2xlarge + 2 replicas): $900
  MongoDB (3x r5.xlarge): $750
  Redis (cache.r5.large cluster): $350
Networking:
  ALB + WAF: $60
  CloudFront CDN: $100
  Data transfer: $200
Monitoring:
  Datadog: $150
  Sentry: $50
Backup & Storage:
  S3 storage: $50
  Backup retention: $30
  
Baseline (minimum): ~$3,570/month
Peak (auto-scaled): ~$10,990/month
```

---

## 8.2 LLM API Cost Projections

### Cost per Model (per 1M tokens)

```yaml
OpenAI:
  GPT-5: $30 input / $60 output
  GPT-4: $10 input / $30 output

Anthropic:
  Claude Opus: $15 input / $75 output
  Claude Sonnet: $3 input / $15 output
  
Google:
  Gemini 2.0: $2 input / $6 output
  Gemini 1.5: $1 input / $3 output

xAI:
  Grok: $5 input / $15 output
```

### Review Cost Analysis

**Typical Code Review (500 lines):**

- Input: ~2,000 tokens (code + context)
- Output per agent: ~1,500 tokens (analysis + suggestions)
- Agents used: 4 (security, readability, performance, tests)

**Cost per Review:**

```python
# Using mix of models
Security (GPT-5): (2000 * 0.00003) + (1500 * 0.00006) = $0.150
Readability (Claude Sonnet): (2000 * 0.000003) + (1500 * 0.000015) = $0.029
Performance (Gemini 2.0): (2000 * 0.000002) + (1500 * 0.000006) = $0.013
Tests (GPT-5): (2000 * 0.00003) + (1500 * 0.00006) = $0.150

Total per review: ~$0.34
```

**Monthly LLM Costs by Volume:**

- 100 reviews/month: $34
- 1,000 reviews/month: $340
- 10,000 reviews/month: $3,400
- 50,000 reviews/month: $17,000

---

## 8.3 Revenue Model & Break-Even Analysis

### Pricing Tiers

```yaml
Free:
  Price: $0
  Reviews: 50/month
  Features: Basic review only
  Cost to serve: $17/month

Pro:
  Price: $29/month
  Reviews: 1,000/month
  Features: All features + integrations
  Cost to serve: $340/month LLM + $5 infrastructure = $345
  Margin: Loss leader (customer acquisition)

Enterprise:
  Price: $299/month
  Reviews: 10,000/month
  Features: Everything + priority support
  Cost to serve: $3,400 LLM + $50 infrastructure = $3,450
  Margin: Negative until >900 reviews/mo used
  
Enterprise Plus:
  Price: Custom (starting $999/month)
  Reviews: Unlimited
  Features: On-premise, custom models
  Cost: Variable by usage
```

### Break-Even Analysis

**Assumptions:**

- Fixed costs: $3,570/month (baseline infrastructure)
- Variable cost: $0.34 per review (LLM APIs)
- Average revenue per paying user: $150/month
- Free tier cost: $17/user/month

**Break-Even:**

- Need 24 paying customers to cover baseline infrastructure
- Need 70% of Pro users to perform >500 reviews/month to be profitable
- Enterprise customers profitable at >1,200 reviews/month

**Year 1 Target:**

- 100 paying customers × $150 = $15,000/month revenue
- Costs: $3,570 infrastructure + $5,000 LLM + $2,000 overhead = $10,570
- Profit: $4,430/month ($53,160/year)

---

# 9. Service Level Agreements (SLAs/SLOs)

## 9.1 Service Level Objectives (SLOs)

### Availability SLO

```yaml
Target: 99.9% uptime (monthly)
Allowed downtime: 43.2 minutes/month
Measurement: 
  - HTTP 200-299 responses / total requests
  - Measured via external monitoring (Pingdom)
  - Excludes scheduled maintenance windows

Tiers:
  Free: 99.0% (no SLA)
  Pro: 99.5% (credits for breaches)
  Enterprise: 99.9% (financial penalties)
```

### Latency SLO

```yaml
API Response Time:
  p50: < 2 seconds
  p95: < 5 seconds
  p99: < 10 seconds
  
Multi-Agent Review:
  p50: < 8 seconds
  p95: < 15 seconds
  p99: < 30 seconds

Measurement: Server-side latency excluding network
Error budget: 0.1% of requests may exceed targets
```

### Correctness SLO

```yaml
Review Accuracy:
  Target: 90% of suggestions rated "helpful" or better
  Measurement: User feedback ratings
  Review period: Rolling 30 days
  
False Positive Rate:
  Target: < 15% of flagged issues are false positives
  Measurement: User dismissal rate
  
Breaking Changes:
  Target: < 1% of refactored code introduces bugs
  Measurement: User-reported issues within 7 days
```

### Support SLO

```yaml
Response Times:
  Critical (system down): 1 hour
  High (major feature broken): 4 hours
  Medium (feature degraded): 24 hours
  Low (questions, enhancements): 48 hours

Resolution Times:
  Critical: 4 hours
  High: 24 hours
  Medium: 72 hours
  Low: Best effort
```

---

## 9.2 Error Budgets

**Monthly Error Budget (99.9% SLA):**

- Allowed error budget: 43.2 minutes downtime
- If 50% consumed: Yellow alert, freeze risky deployments
- If 75% consumed: Red alert, emergency response
- If 100% consumed: Post-mortem required, deployment freeze

**Error Budget Policy:**

```python
if error_budget_remaining < 25%:
    - Pause non-critical feature releases
    - Focus on reliability improvements
    - Increase monitoring and alerting
    - Mandatory incident reviews
elif error_budget_remaining < 50%:
    - Require senior approval for deployments
    - Enhanced testing for all changes
    - Double-check rollback procedures
else:
    - Normal deployment cadence
    - Continue feature development
```

---

# 10. Observability Strategy

## 10.1 Logging Standards

### Log Levels

```python
import logging

# Log level guidelines
CRITICAL  # System is unusable (database down, all models failing)
ERROR     # Operation failed, user affected (review failed, API error)
WARNING   # Degraded state (high latency, fallback model used)
INFO      # Normal operations (review completed, user logged in)
DEBUG     # Detailed troubleshooting (variable values, flow control)
```

### Structured Logging Format

```json
{
  "timestamp": "2025-11-11T18:30:00.123Z",
  "level": "INFO",
  "service": "orchestrator",
  "trace_id": "abc123def456",
  "span_id": "span789",
  "user_id": "user_123",
  "review_id": "rev_xyz",
  "message": "Review completed successfully",
  "duration_ms": 4523,
  "model_used": "gpt-5",
  "metadata": {
    "language": "python",
    "loc": 234,
    "agents_used": ["security", "readability"]
  }
}
```

### Log Retention Policy

```yaml
Development:
  Retention: 7 days
  Storage: Local files
  
Staging:
  Retention: 30 days
  Storage: CloudWatch Logs
  
Production:
  Hot storage: 30 days (searchable)
  Warm storage: 90 days (archive)
  Cold storage: 1 year (compliance)
  Storage: CloudWatch + S3
```

---

## 10.2 Distributed Tracing

### Trace Implementation (OpenTelemetry)

```python
from opentelemetry import trace
from opentelemetry.trace import Status, StatusCode

tracer = trace.get_tracer(__name__)

@tracer.start_as_current_span("review_code")
def review_code(code: str, user_id: str):
    span = trace.get_current_span()
    span.set_attribute("[user.id](http://user.id)", user_id)
    span.set_attribute("code.length", len(code))
    
    try:
        # Orchestrate review
        with tracer.start_as_current_span("detect_language"):
            language = detect_language(code)
            span.set_attribute("code.language", language)
        
        with tracer.start_as_current_span("parallel_agent_calls"):
            results = execute_agents_parallel(code, language)
        
        with tracer.start_as_current_span("aggregate_results"):
            final_result = aggregate(results)
        
        span.set_status(Status(StatusCode.OK))
        return final_result
        
    except Exception as e:
        span.set_status(Status(StatusCode.ERROR))
        span.record_exception(e)
        raise
```

### Trace Sampling Strategy

```yaml
Production:
  Head-based sampling: 10% of all traces
  Tail-based sampling: 100% of errors and slow requests (>30s)
  Priority sampling: 100% of Enterprise tier users
  
Staging:
  Sample rate: 50%
  
Development:
  Sample rate: 100%
```

---

## 10.3 Metrics & Instrumentation

### Application Metrics (Prometheus)

```python
from prometheus_client import Counter, Histogram, Gauge

# Request metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

# Business metrics
reviews_total = Counter(
    'reviews_total',
    'Total code reviews performed',
    ['language', 'user_tier']
)

review_duration_seconds = Histogram(
    'review_duration_seconds',
    'Review processing time',
    ['language', 'agent_count']
)

# Model metrics
model_api_calls_total = Counter(
    'model_api_calls_total',
    'LLM API calls',
    ['model', 'status']
)

model_api_cost_usd = Counter(
    'model_api_cost_usd',
    'LLM API costs',
    ['model']
)

# System metrics
active_workers = Gauge(
    'active_workers',
    'Number of active worker processes'
)

queue_depth = Gauge(
    'queue_depth',
    'Number of pending reviews in queue',
    ['priority']
)
```

### Alert Definitions

```yaml
alerts:
  - name: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
    for: 2m
    severity: critical
    message: "Error rate above 5% for 2 minutes"
    
  - name: HighLatency
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 10
    for: 5m
    severity: warning
    message: "p95 latency above 10s"
    
  - name: ModelAPIFailures
    expr: rate(model_api_calls_total{status="error"}[5m]) > 0.1
    for: 1m
    severity: high
    message: "Model API failure rate above 10%"
    
  - name: QueueBacklog
    expr: queue_depth{priority="normal"} > 1000
    for: 10m
    severity: warning
    message: "Review queue backing up"
    
  - name: HighCosts
    expr: rate(model_api_cost_usd[1h]) > 10
    for: 1m
    severity: warning
    message: "API costs exceeding $10/hour"
```

---

# 11. Testing Strategy

## 11.1 Test Pyramid

```
      /\
     /E2E\          10% - End-to-end tests
    /------\
   /  API  \        20% - Integration tests
  /----------\
 /   Unit     \     70% - Unit tests
/--------------\
```

### Unit Tests (70% coverage target)

```python
# Example: Test agent selection logic
import pytest
from orchestrator import select_agents

def test_select_agents_for_python():
    agents = select_agents(language="python", user_tier="pro")
    assert "security" in agents
    assert "test_generator" in agents
    assert len(agents) >= 4

def test_select_agents_respects_tier():
    free_agents = select_agents(language="python", user_tier="free")
    pro_agents = select_agents(language="python", user_tier="pro")
    assert len(pro_agents) > len(free_agents)

@pytest.mark.parametrize("language,expected_agent", [
    ("python", "performance_analyzer"),
    ("javascript", "performance_analyzer"),
    ("rust", "memory_analyzer"),
])
def test_language_specific_agents(language, expected_agent):
    agents = select_agents(language=language)
    assert expected_agent in agents
```

**Coverage Requirements:**

- Critical paths: 90%+ coverage
- Business logic: 80%+ coverage
- Utility functions: 70%+ coverage
- Configuration code: 50%+ coverage

---

## 11.2 Integration Tests (20%)

```python
# Example: Test full review flow with mocked LLM
import pytest
from unittest.mock import patch, MagicMock

@pytest.mark.integration
async def test_complete_review_flow():
    # Mock LLM responses
    with patch('model_gateway.ModelGateway.complete') as mock_llm:
        mock_llm.return_value = MagicMock(
            content='{"findings": [{"severity": "high", "message": "SQL injection"}]}',
            usage={'total_tokens': 1500},
            cost_usd=0.15
        )
        
        # Submit review
        response = await [client.post](http://client.post)('/reviews', json={
            'code': 'SELECT * FROM users WHERE id = ' + user_input,
            'language': 'python'
        })
        
        assert response.status_code == 200
        review_id = response.json()['review_id']
        
        # Wait for completion
        await wait_for_completion(review_id, timeout=30)
        
        # Verify results
        review = await client.get(f'/reviews/{review_id}')
        assert review.json()['status'] == 'completed'
        assert len(review.json()['findings']) > 0
        assert any('SQL injection' in f['message'] for f in review.json()['findings'])

@pytest.mark.integration
def test_database_transactions():
    # Test rollback on error
    with pytest.raises(ValidationError):
        with db_session() as session:
            user = User(email="[test@example.com](mailto:test@example.com)")
            session.add(user)
            session.commit()
            
            # This should fail and rollback
            review = Review(user_id=[user.id](http://user.id), code="x" * 1_000_000)  # Too large
            session.add(review)
            session.commit()
    
    # Verify user was not created due to rollback
    with db_session() as session:
        assert session.query(User).filter_by(email="[test@example.com](mailto:test@example.com)").first() is None
```

---

## 11.3 End-to-End Tests (10%)

```python
# Example: Full user journey test
@pytest.mark.e2e
async def test_complete_user_journey():
    # 1. User signup
    signup_response = await [client.post](http://client.post)('/auth/signup', json={
        'email': '[newuser@example.com](mailto:newuser@example.com)',
        'password': 'SecurePass123!'
    })
    assert signup_response.status_code == 201
    
    # 2. User login
    login_response = await [client.post](http://client.post)('/auth/login', json={
        'email': '[newuser@example.com](mailto:newuser@example.com)',
        'password': 'SecurePass123!'
    })
    token = login_response.json()['access_token']
    
    # 3. Submit code review
    review_response = await [client.post](http://client.post)(
        '/reviews',
        headers={'Authorization': f'Bearer {token}'},
        json={'code': SAMPLE_CODE, 'language': 'python'}
    )
    review_id = review_response.json()['review_id']
    
    # 4. Poll for completion
    for _ in range(30):
        status_response = await client.get(
            f'/reviews/{review_id}',
            headers={'Authorization': f'Bearer {token}'}
        )
        if status_response.json()['status'] == 'completed':
            break
        await asyncio.sleep(1)
    
    # 5. Verify results
    review = status_response.json()
    assert review['status'] == 'completed'
    assert 'refined_code' in review
    assert 'scores' in review
    assert all(score > 0 for score in review['scores'].values())
    
    # 6. Export to Notion (if Pro user)
    export_response = await [client.post](http://client.post)(
        f'/reviews/{review_id}/export/notion',
        headers={'Authorization': f'Bearer {token}'}
    )
    assert export_response.status_code in [200, 403]  # 403 if free tier
```

---

## 11.4 Load Testing

### Load Test Scenarios (using Locust)

```python
from locust import HttpUser, task, between

class CodeReviewUser(HttpUser):
    wait_time = between(1, 5)
    
    def on_start(self):
        # Login once per user
        response = [self.client.post](http://self.client.post)('/auth/login', json={
            'email': '[loadtest@example.com](mailto:loadtest@example.com)',
            'password': 'LoadTest123!'
        })
        self.token = response.json()['access_token']
    
    @task(3)
    def submit_small_review(self):
        """Most common: small code snippet review"""
        [self.client.post](http://self.client.post)(
            '/reviews',
            headers={'Authorization': f'Bearer {self.token}'},
            json={
                'code': SMALL_CODE_SNIPPET,  # ~100 lines
                'language': 'python'
            }
        )
    
    @task(1)
    def submit_large_review(self):
        """Less common: large file review"""
        [self.client.post](http://self.client.post)(
            '/reviews',
            headers={'Authorization': f'Bearer {self.token}'},
            json={
                'code': LARGE_CODE_FILE,  # ~1000 lines
                'language': 'python'
            }
        )
    
    @task(2)
    def check_review_status(self):
        """Poll for review status"""
        if hasattr(self, 'last_review_id'):
            self.client.get(
                f'/reviews/{self.last_review_id}',
                headers={'Authorization': f'Bearer {self.token}'}
            )
```

### Load Test Targets

```yaml
Baseline Load:
  Users: 50 concurrent
  Requests: 100 req/s
  Duration: 30 minutes
  Success rate: > 99%
  p95 latency: < 5s

Peak Load:
  Users: 200 concurrent
  Requests: 400 req/s
  Duration: 10 minutes
  Success rate: > 95%
  p95 latency: < 15s

Stress Test:
  Users: Ramp to 1000
  Goal: Find breaking point
  Monitor: Error rates, latency, resource usage
```

---

# 12. Migration Strategy (Phase 0 → Phase 1+)

## 12.1 Migration Phases

### Phase 0: Gemini Prototype (Current)

**What exists:**

- Google AI Studio with prompt-based system
- Manual copy-paste workflow
- No persistence
- Single model (Gemini)

**Duration:** 2-4 weeks

---

### Phase 1: Basic Infrastructure (Weeks 1-4)

**Goal:** Deploy minimal working system with API

**Tasks:**

1. **Week 1: Foundation**
    - Set up AWS account and VPC
    - Deploy PostgreSQL RDS
    - Deploy Redis ElastiCache
    - Configure secrets management
    - Set up CI/CD pipeline
2. **Week 2: API Development**
    - Build FastAPI application
    - Implement authentication (JWT)
    - Create `/reviews` endpoint
    - Add basic validation
    - Deploy to development environment
3. **Week 3: Orchestrator & Agents**
    - Implement orchestrator service
    - Create agent base classes
    - Integrate OpenAI and Anthropic APIs
    - Build model gateway abstraction
    - Add Celery for async processing
4. **Week 4: Testing & Staging**
    - Write unit tests (50% coverage)
    - Deploy to staging
    - Load testing (basic)
    - Fix critical bugs
    - Documentation

**Success Criteria:**

- API accepts code and returns reviews
- Single-model reviews work end-to-end
- Basic authentication functional
- Staging environment stable

---

### Phase 2: Multi-Model Orchestration (Weeks 5-8)

**Goal:** Implement parallel agent execution and model routing

**Tasks:**

1. **Multi-agent coordination**
    - Parallel agent execution
    - Result aggregation logic
    - Confidence scoring
    - Conflict resolution
2. **Model optimization**
    - Add all model providers
    - Implement fallback chains
    - Cost tracking per review
    - Model selection algorithm
3. **Enhanced features**
    - Diff generation
    - Test generation
    - Quality scoring
    - Export to JSON

**Migration Path:**

- Run Phase 0 and Phase 1 in parallel
- Gradually shift users to new API
- A/B test quality improvements
- Monitor costs closely

---

### Phase 3: Integrations (Weeks 9-12)

**Goal:** Connect to external platforms

**Tasks:**

1. **Notion integration**
    - Database schema mapping
    - Bidirectional sync
    - Review history tracking
2. **GitHub integration**
    - PR comment bot
    - GitHub Actions
    - Issue creation
3. **IDE plugins (basic)**
    - VSCode extension (read-only)
    - Copy-paste workflow
    - Status display

**Data Migration:**

- Export Phase 0 history (if any) to JSON
- Import into PostgreSQL
- Generate embeddings for existing reviews
- Backfill user data

---

### Phase 4: Production Hardening (Weeks 13-16)

**Goal:** Production-ready system with monitoring

**Tasks:**

1. **Observability**
    - Full logging pipeline
    - Distributed tracing
    - Grafana dashboards
    - PagerDuty integration
2. **Security hardening**
    - Penetration testing
    - Secrets audit
    - Rate limiting
    - DDoS protection (Cloudflare)
3. **Performance optimization**
    - Database indexing
    - Query optimization
    - Caching strategy
    - Multi-region deployment
4. **Documentation**
    - API documentation (OpenAPI)
    - User guides
    - Runbooks
    - Architecture decision records

**Cutover Plan:**

```yaml
Week 15:
  - Feature freeze
  - Final load testing
  - Security audit
  - Backup procedures tested

Week 16:
  - Staged rollout (10% → 50% → 100% of users)
  - Monitor metrics closely
  - Keep Phase 0 as fallback for 2 weeks
  - Post-launch retrospective
```

---

## 12.2 Rollback Plan

**Triggers for rollback:**

- Error rate > 10% for 5 minutes
- p95 latency > 30s for 10 minutes
- Data corruption detected
- Security breach

**Rollback procedure:**

1. Switch DNS/load balancer to Phase 0 system (if still running)
2. Disable new user registrations on Phase 1
3. Export any new data from Phase 1
4. Investigate root cause
5. Fix and redeploy
6. Gradual re-cutover (10% → 50% → 100%)

**Rollback time target:** < 15 minutes

---

# 13. Operational Runbooks

## 13.1 Deployment Procedures

### Standard Deployment Checklist

**Pre-deployment (30 minutes before):**

- [ ]  All tests passing in CI
- [ ]  Code review approved by 2+ engineers
- [ ]  Database migrations reviewed and tested
- [ ]  Rollback plan documented
- [ ]  On-call engineer identified
- [ ]  Stakeholders notified (if major change)

**Deployment steps:**

```bash
# 1. Tag release
git tag -a v1.2.3 -m "Release v1.2.3: Feature X"
git push origin v1.2.3

# 2. Trigger CI/CD pipeline
# (GitHub Actions will automatically build and deploy to staging)

# 3. Verify staging deployment
curl [https://staging-api.codealchemist.dev/health](https://staging-api.codealchemist.dev/health)
kubectl get pods -n code-alchemist-staging

# 4. Run smoke tests
pytest tests/smoke/ --env=staging

# 5. Deploy to production (manual approval)
# Approve GitHub Actions deployment

# 6. Monitor for 30 minutes
# Watch Grafana dashboard, error rates, latency

# 7. Verify production
curl [https://api.codealchemist.dev/health](https://api.codealchemist.dev/health)
kubectl get pods -n code-alchemist

# 8. Announce deployment
# Post to #engineering-deploys Slack channel
```

**Post-deployment (30 minutes after):**

- [ ]  Monitor error rates (should be < 1%)
- [ ]  Check latency metrics (p95 < 5s)
- [ ]  Verify no increase in 5xx errors
- [ ]  Test critical user flows manually
- [ ]  Review logs for anomalies
- [ ]  Update deployment log

**If issues detected:**

1. Assess severity (critical vs minor)
2. If critical: Initiate rollback immediately
3. If minor: Create incident ticket, monitor
4. Post-mortem within 48 hours

---

## 13.2 Rollback Procedures

### Emergency Rollback (< 15 minutes)

```bash
# 1. Announce rollback
echo "INCIDENT: Rolling back deployment v1.2.3" | post-to-slack

# 2. Rollback Kubernetes deployment
kubectl rollout undo deployment/code-alchemist-api -n code-alchemist
kubectl rollout undo deployment/code-alchemist-workers -n code-alchemist

# 3. Verify rollback
kubectl rollout status deployment/code-alchemist-api -n code-alchemist

# 4. Rollback database migrations (if any)
alembic downgrade -1

# 5. Clear caches (if schema changed)
redis-cli FLUSHDB

# 6. Monitor recovery
# Watch error rates return to normal
# Verify latency is back to baseline

# 7. Incident report
# Document what went wrong
# Create post-mortem issue
```

### Database Migration Rollback

```bash
# If migration applied in deployment:
alembic downgrade <previous_revision>

# Verify data integrity
python scripts/verify_data_[integrity.py](http://integrity.py)

# If data corruption occurred:
# 1. Stop all writes to database
kubectl scale deployment/code-alchemist-api --replicas=0

# 2. Restore from latest backup
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier prod-db \
  --target-db-instance-identifier prod-db-restore \
  --restore-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%SZ)

# 3. Verify restore
psql -h [prod-db-restore.xxx.rds.amazonaws.com](http://prod-db-restore.xxx.rds.amazonaws.com) -U admin -d codealchemist

# 4. Swap endpoints (requires DNS change or RDS rename)
# This is a multi-step AWS console operation

# 5. Resume traffic
kubectl scale deployment/code-alchemist-api --replicas=3
```

---

## 13.3 Common Troubleshooting Scenarios

### Scenario 1: High Latency (p95 > 10s)

**Symptoms:**

- User reports slow responses
- Grafana shows latency spike
- No increase in error rates

**Diagnosis steps:**

```bash
# 1. Check active requests
kubectl top pods -n code-alchemist

# 2. Check database performance
psql -h [prod-db.rds.amazonaws.com](http://prod-db.rds.amazonaws.com) -c "SELECT * FROM pg_stat_activity WHERE state = 'active';"

# 3. Check model API latency
curl [https://api.codealchemist.dev/internal/metrics](https://api.codealchemist.dev/internal/metrics) | grep model_api_latency

# 4. Check queue depth
redis-cli GET queue_depth
```

**Common causes & fixes:**

- **Database slow queries:** Optimize query or add index
- **Model API slow:** Switch to faster model or increase timeout
- **Queue backlog:** Scale up workers
- **Memory pressure:** Increase pod resources

**Resolution:**

```bash
# If worker shortage:
kubectl scale deployment/code-alchemist-workers --replicas=10

# If database bottleneck:
# Promote read replica to handle read traffic

# If model API slow:
# Update model selection to use faster alternatives
kubectl set env deployment/code-alchemist-api FALLBACK_MODEL=gemini-1.5
```

---

### Scenario 2: Model API Failures

**Symptoms:**

- Error rate spike to 20%+
- Logs show "ModelAPIError"
- Reviews stuck in "processing" state

**Diagnosis:**

```bash
# 1. Check model API status
curl [https://status.openai.com](https://status.openai.com)
curl [https://status.anthropic.com](https://status.anthropic.com)

# 2. Check API key validity
python scripts/test_model_[keys.py](http://keys.py)

# 3. Check rate limits
redis-cli GET ratelimit:openai:requests

# 4. Review error logs
kubectl logs -n code-alchemist deployment/code-alchemist-workers --tail=100 | grep ModelAPIError
```

**Resolution:**

```bash
# If OpenAI is down:
# Force all traffic to Anthropic
kubectl set env deployment/code-alchemist-api PRIMARY_MODEL_PROVIDER=anthropic

# If rate limited:
# Slow down request rate
kubectl set env deployment/code-alchemist-api MAX_CONCURRENT_MODEL_CALLS=5

# If API keys invalid:
# Rotate keys from AWS Secrets Manager
aws secretsmanager update-secret --secret-id llm-api-keys --secret-string '{\"openai\":\"sk-new-key\"}'
kubectl rollout restart deployment/code-alchemist-api
```

---

### Scenario 3: Database Connection Exhaustion

**Symptoms:**

- Error: "FATAL: too many connections"
- API returns 500 errors
- Database CPU at 100%

**Diagnosis:**

```bash
# Check active connections
psql -h [prod-db.rds.amazonaws.com](http://prod-db.rds.amazonaws.com) -c "SELECT count(*) FROM pg_stat_activity;"

# Check connection pool status
kubectl exec -it deployment/code-alchemist-api -- python -c "from db import engine; print(engine.pool.status())"
```

**Resolution:**

```bash
# Immediate fix: Kill idle connections
psql -h [prod-db.rds.amazonaws.com](http://prod-db.rds.amazonaws.com) -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state = 'idle' AND state_change < NOW() - INTERVAL '5 minutes';"

# Long-term fix: Adjust pool settings
kubectl set env deployment/code-alchemist-api DB_POOL_SIZE=10 DB_MAX_OVERFLOW=5

# Or deploy PgBouncer
helm install pgbouncer bitnami/pgbouncer --set [postgresql.host](http://postgresql.host)=[prod-db.rds.amazonaws.com](http://prod-db.rds.amazonaws.com)
```

---

### Scenario 4: Redis Cache Eviction Storm

**Symptoms:**

- Cache hit rate drops to <20%
- Database load spikes
- Latency increases across the board

**Diagnosis:**

```bash
# Check Redis memory usage
redis-cli INFO memory

# Check eviction count
redis-cli INFO stats | grep evicted_keys

# Check cache hit rate
redis-cli INFO stats | grep keyspace_hits
```

**Resolution:**

```bash
# Immediate: Scale Redis vertically
# (Requires recreation, brief downtime)
aws elasticache modify-cache-cluster \
  --cache-cluster-id prod-redis \
  --cache-node-type cache.r5.xlarge \
  --apply-immediately

# Or add nodes to cluster
aws elasticache increase-replica-count \
  --replication-group-id prod-redis-cluster \
  --new-replica-count 3 \
  --apply-immediately

# Adjust eviction policy
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Optimize TTLs (reduce cache size)
# Update application config
kubectl set env deployment/code-alchemist-api CACHE_TTL=1800  # 30 min instead of 1 hour
```

---

## 13.4 On-Call Runbook

### On-Call Responsibilities

- Respond to PagerDuty alerts within 15 minutes
- Triage incidents by severity
- Escalate to senior engineers if needed
- Document all incidents in post-mortems

### Alert Response Guide

**Critical Alert (P1):**

- System down or major feature broken
- Customer-facing impact
- Response SLA: 15 minutes
- Resolution SLA: 4 hours

**Action:**

1. Acknowledge alert in PagerDuty
2. Join #incidents Slack channel
3. Announce incident: "P1: [Brief description]"
4. Diagnose using runbooks above
5. Page senior engineer if unresolved in 30 min
6. Update stakeholders every 30 min
7. Create post-mortem ticket after resolution

**High Alert (P2):**

- Degraded performance
- Some users affected
- Response SLA: 30 minutes
- Resolution SLA: 24 hours

**Warning Alert (P3):**

- Potential issue
- No immediate user impact
- Response SLA: 2 hours
- Resolution SLA: 72 hours

---

**Document Status:** Enhanced - Ready for Technical Review

**Version:** 2.0.0

**Last Updated:** 2025-11-11

**Next Review:** 2025-12-11

**Changelog:**

- Added comprehensive cost analysis and revenue projections
- Added SLA/SLO definitions with error budgets
- Added complete observability strategy (logging, tracing, metrics)
- Added testing strategy with pyramid and code examples
- Added migration strategy from Phase 0 to production
- Added operational runbooks for deployment, rollback, and troubleshooting
- Added on-call procedures and common incident responses