# Agent Specifications

# Agent Specifications

**Project:** Codessa Code Alchemist ∞

**Version:** 1.0.0

**Last Updated:** 2025-11-11

---

## Overview

This document provides detailed specifications for each AI agent in the Code Alchemist system, including prompt engineering, input/output schemas, model selection criteria, and fallback strategies.

---

# 1. Syntax & Formatting Agent

## Purpose

Detect programming language, validate syntax correctness, and suggest style improvements.

## Capabilities

- Language detection (20+ languages)
- Syntax validation
- Code style compliance (PEP 8, ESLint, etc.)
- Formatting suggestions
- Import organization

## Model Selection

**Primary:** Claude Sonnet 3.5

**Fallback:** GPT-4

**Rationale:** Claude excels at structured analysis and follows instructions precisely.

## Input Schema

```json
{
  "code": "string (required)",
  "filename": "string (optional)",
  "language": "string (optional, hint)",
  "style_guide": "string (optional, e.g., 'pep8', 'google')"
}
```

## Prompt Template

```
You are a code syntax and formatting expert. Analyze the following code:

```

{code}

```

Tasks:
1. Detect the programming language (if not specified)
2. Check for syntax errors
3. Evaluate adherence to {style_guide} style guide
4. Suggest formatting improvements

Provide your analysis in this JSON format:
{
  "language": "detected language",
  "syntax_valid": true/false,
  "syntax_errors": [{"line": int, "message": "string"}],
  "style_score": 0-10,
  "style_issues": [{"line": int, "severity": "low|medium|high", "message": "string", "suggestion": "string"}],
  "confidence": 0-1
}
```

## Output Schema

```json
{
  "agent": "syntax_formatting",
  "language": "python",
  "syntax_valid": true,
  "syntax_errors": [],
  "style_score": 8.5,
  "style_issues": [
    {
      "line": 12,
      "severity": "medium",
      "message": "Line too long (92 > 79 characters)",
      "suggestion": "Break into multiple lines"
    }
  ],
  "confidence": 0.95,
  "model_used": "claude-sonnet-3.5",
  "processing_time_ms": 1234
}
```

## Error Handling

- If language detection fails: Return "unknown" and continue with generic analysis
- If model API fails: Fallback to GPT-4, then return static analysis only
- If code is too large (>100KB): Chunk and analyze sections

---

# 2. Code Review Agent

## Purpose

Analyze code for readability, structure, naming conventions, and maintainability.

## Capabilities

- Readability assessment
- Naming convention analysis
- Code smell detection
- Complexity metrics
- Refactoring suggestions
- Best practices validation

## Model Selection

**Primary:** GPT-5

**Fallback:** Claude Opus

**Rationale:** GPT-5 has superior code understanding and generates actionable suggestions.

## Input Schema

```json
{
  "code": "string (required)",
  "language": "string (required)",
  "context": "string (optional, e.g., 'microservice', 'library')",
  "focus_areas": ["string array, optional"]
}
```

## Prompt Template

```
You are an expert code reviewer focused on readability and maintainability.

Review this {language} code:

```

{code}

```

Context: {context}

Evaluate:
1. **Readability** (0-10): Is the code easy to understand?
2. **Naming**: Are variables, functions, and classes well-named?
3. **Structure**: Is the code well-organized?
4. **Complexity**: Are there overly complex sections?
5. **Maintainability**: How easy is it to modify?

For each issue found:
- Identify the specific line(s)
- Explain the problem
- Suggest a concrete improvement
- Rate severity (low/medium/high)

Provide analysis as JSON:
{
  "readability_score": 0-10,
  "findings": [
    {
      "category": "naming|structure|complexity|maintainability",
      "line": int,
      "severity": "low|medium|high",
      "issue": "description",
      "suggestion": "specific improvement",
      "code_example": "improved code snippet"
    }
  ],
  "summary": "brief overview",
  "confidence": 0-1
}
```

## Output Schema

```json
{
  "agent": "code_review",
  "readability_score": 7.5,
  "findings": [
    {
      "category": "naming",
      "line": 15,
      "severity": "medium",
      "issue": "Variable 'x' is not descriptive",
      "suggestion": "Rename to 'user_count' to clarify purpose",
      "code_example": "user_count = len(users)"
    }
  ],
  "summary": "Code is generally readable but naming could be more descriptive.",
  "confidence": 0.88,
  "model_used": "gpt-5",
  "processing_time_ms": 2456
}
```

---

# 3. Security Auditor Agent

## Purpose

Identify security vulnerabilities, unsafe practices, and potential exploits.

## Capabilities

- OWASP Top 10 detection
- SQL injection scanning
- XSS vulnerability detection
- Authentication/authorization issues
- Secrets detection (API keys, passwords)
- Dependency vulnerability checking

## Model Selection

**Primary:** GPT-5

**Fallback:** Claude Opus → Grok

**Rationale:** GPT-5 has extensive security knowledge; Grok good at edge cases.

## Input Schema

```json
{
  "code": "string (required)",
  "language": "string (required)",
  "dependencies": ["string array, optional"],
  "framework": "string (optional)"
}
```

## Prompt Template

```
You are a security expert conducting a code security audit.

Analyze this {language} code for security vulnerabilities:

```

{code}

```

Framework: {framework}
Dependencies: {dependencies}

Check for:
1. **Injection Attacks**: SQL, NoSQL, command injection, XSS
2. **Authentication/Authorization**: Weak auth, privilege escalation
3. **Sensitive Data**: Hardcoded secrets, insecure storage
4. **Cryptography**: Weak algorithms, poor key management
5. **Input Validation**: Insufficient validation, sanitization
6. **Error Handling**: Information leakage
7. **Dependencies**: Known CVEs

For each vulnerability:
- Classify by OWASP category
- Rate severity (critical/high/medium/low)
- Explain the attack vector
- Provide remediation code

Return JSON:
{
  "security_score": 0-10,
  "vulnerabilities": [
    {
      "type": "sql_injection|xss|auth|secrets|crypto|input_validation",
      "severity": "critical|high|medium|low",
      "line": int,
      "description": "vulnerability details",
      "attack_vector": "how it can be exploited",
      "remediation": "fix suggestion",
      "secure_code_example": "corrected code",
      "cwe_id": "string (e.g., CWE-89)"
    }
  ],
  "confidence": 0-1
}
```

## Output Schema

```json
{
  "agent": "security_auditor",
  "security_score": 6.2,
  "vulnerabilities": [
    {
      "type": "sql_injection",
      "severity": "critical",
      "line": 42,
      "description": "SQL query constructed with string concatenation using user input",
      "attack_vector": "Attacker can inject malicious SQL via 'user_id' parameter",
      "remediation": "Use parameterized queries",
      "secure_code_example": "cursor.execute('SELECT * FROM users WHERE id = ?', (user_id,))",
      "cwe_id": "CWE-89"
    }
  ],
  "confidence": 0.93,
  "model_used": "gpt-5",
  "processing_time_ms": 3102
}
```

---

# 4. Performance Analyzer Agent

## Purpose

Identify performance bottlenecks and suggest optimizations.

## Capabilities

- Algorithmic complexity analysis (Big O)
- N+1 query detection
- Memory leak identification
- Inefficient loops
- Resource usage estimation

## Model Selection

**Primary:** Gemini 1.5 Pro

**Fallback:** GPT-5

**Rationale:** Gemini excels at mathematical and algorithmic analysis.

## Prompt Template

```
Analyze this {language} code for performance issues:

```

{code}

```

Tasks:
1. Calculate Big O complexity for each function
2. Identify performance bottlenecks
3. Detect inefficient patterns (N+1 queries, nested loops, etc.)
4. Suggest optimizations

Return JSON:
{
  "performance_score": 0-10,
  "complexity_analysis": [
    {
      "function": "name",
      "time_complexity": "O(...)",
      "space_complexity": "O(...)"
    }
  ],
  "bottlenecks": [
    {
      "line": int,
      "severity": "critical|high|medium|low",
      "issue": "description",
      "optimization": "suggestion",
      "expected_improvement": "percentage or description"
    }
  ],
  "confidence": 0-1
}
```

---

# 5. Test Generator Agent

## Purpose

Generate comprehensive unit and integration tests.

## Capabilities

- Unit test generation
- Integration test scaffolding
- Edge case identification
- Test fixture creation
- Mocking suggestions

## Model Selection

**Primary:** GPT-5

**Fallback:** Gemini 2.0

**Rationale:** GPT-5 generates idiomatic, framework-appropriate tests.

## Prompt Template

```
Generate comprehensive tests for this {language} code:

```

{code}

```

Framework: {test_framework} (e.g., pytest, jest, junit)

Generate:
1. **Unit tests** for each public function
2. **Edge cases** (empty inputs, null, extremes)
3. **Error cases** (invalid inputs, exceptions)
4. **Integration tests** (if applicable)
5. **Test fixtures** and mocks

Return JSON:
{
  "test_code": "complete test file as string",
  "test_cases": [
    {
      "name": "test function name",
      "type": "unit|integration|edge_case",
      "description": "what it tests"
    }
  ],
  "coverage_estimate": "percentage",
  "dependencies": ["required test libraries"],
  "confidence": 0-1
}
```

---

# 6. Documentation Agent

## Purpose

Generate docstrings, comments, and documentation.

## Capabilities

- Docstring generation
- Inline comments
- README sections
- API documentation
- Usage examples

## Model Selection

**Primary:** Claude Sonnet 3.5

**Fallback:** GPT-4

**Rationale:** Claude produces clear, well-structured documentation.

---

# Agent Coordination

## Parallel Execution

Agents run concurrently to minimize latency:

```python
import asyncio

results = await asyncio.gather(
    syntax_agent.analyze(code),
    review_agent.analyze(code),
    security_agent.analyze(code),
    performance_agent.analyze(code),
    test_agent.generate(code),
    doc_agent.generate(code)
)
```

## Result Aggregation

1. Collect all agent outputs
2. Deduplicate findings (same issue detected by multiple agents)
3. Calculate weighted confidence scores
4. Merge into unified output
5. Generate final recommendations

## Conflict Resolution

When agents disagree:

1. Higher confidence score wins
2. Security findings always included (conservative)
3. User can see individual agent outputs

---

**Next Steps:**

- Implement prompt templates in code
- A/B test different models per agent
- Tune confidence thresholds
- Add agent-specific metrics