# FAQ (Frequently Asked Questions)

# FAQ - Codessa Code Alchemist

**Last Updated:** 2025-11-11

---

## 🎯 General Questions

### What is Codessa Code Alchemist?

Codessa Code Alchemist is an AI-powered code review and refinement platform that uses multiple specialized LLMs to analyze, review, and improve your code. Think of it as having a team of expert code reviewers available 24/7.

### Who is it for?

- **Individual Developers:** Get instant code reviews on personal projects
- **Teams:** Standardize code quality across your organization
- **Students:** Learn best practices from AI feedback
- **Open Source Maintainers:** Scale code review capacity

### How is it different from GitHub Copilot or ChatGPT?

| Feature | Code Alchemist | GitHub Copilot | ChatGPT |
| --- | --- | --- | --- |
| **Purpose** | Comprehensive code review | Code completion | General chat |
| **Multi-Agent** | 6 specialized agents | Single model | Single model |
| **Security Audit** | ✅ OWASP Top 10 | ❌ | Limited |
| **Test Generation** | ✅ Full suite | ❌ | Manual |
| **Notion Integration** | ✅ Native | ❌ | ❌ |
| **Confidence Scores** | ✅ Per finding | ❌ | ❌ |
| **Cost** | $0.34/review | $10-20/month | $20/month |

---

## 💰 Pricing & Plans

### How much does it cost?

**Phase 0 (Current):** Free during prototype phase

**Phase 1+ (Planned):**

- **Free Tier:** 50 reviews/month, basic features
- **Pro:** $29/month - 1,000 reviews, all features
- **Enterprise:** $299/month - 10,000 reviews, priority support

### What's the cost per review?

Approximately **$0.34 per review** (for a typical 500-line file with 4 agents).

### Can I use my own API keys?

Yes! Enterprise plan allows you to use your own OpenAI/Anthropic/Google API keys, potentially reducing costs by 60%+.

---

## 🔒 Security & Privacy

### Is my code secure?

**Yes.** We take security seriously:

- Code is encrypted in transit (TLS 1.3) and at rest (AES-256)
- We don't train models on your code
- Code is deleted after 30 days (configurable)
- SOC 2 compliance planned for 2026

### Who can see my code?

**Only you.** Your code is:

- Sent to LLM providers for analysis (per their privacy policies)
- Stored temporarily in your private database
- Never shared with other users
- Never used for model training

### What about secrets in my code?

Our Security Auditor Agent **detects hardcoded secrets** (API keys, passwords) and flags them. We also sanitize secrets before logging.

### Is it GDPR/CCPA compliant?

Yes (planned for Phase 4). You can:

- Export all your data
- Delete your account and all associated data
- Request data deletion at any time

---

## 🛠️ Technical Questions

### Which programming languages are supported?

**Phase 0:** Python, JavaScript, TypeScript

**Phase 1+:** Python, JavaScript, TypeScript, Java, Go, Rust, C++, C#, PHP, Ruby, Swift, Kotlin

### How long does a review take?

- **Simple review (1 agent):** 2-5 seconds
- **Multi-agent review (4-6 agents):** 8-15 seconds
- **Large files (>1000 lines):** 20-30 seconds

### What's the maximum code size?

**500KB per review** (approximately 10,000-15,000 lines of code). Larger files can be split.

### Can it review pull requests automatically?

Yes! Our GitHub integration (Phase 3) automatically reviews PRs and posts findings as comments.

### Does it work offline?

No. Code Alchemist requires internet access to reach LLM APIs. However, you can self-host and use local models (enterprise only, Phase 5+).

### What frameworks/libraries does it understand?

It understands most popular frameworks:

- **Web:** React, Vue, Angular, Django, Flask, Express, Next.js
- **Mobile:** React Native, Flutter, Swift UI
- **Backend:** FastAPI, Spring Boot, [ASP.NET](http://ASP.NET), Rails
- **ML:** TensorFlow, PyTorch, scikit-learn

---

## 🎨 Features & Capabilities

### What does each agent do?

**1. Syntax & Formatting Agent**

- Detects language and framework
- Validates syntax
- Checks style compliance (PEP 8, ESLint, etc.)

**2. Code Review Agent**

- Analyzes readability and structure
- Detects code smells
- Suggests refactoring

**3. Security Auditor Agent**

- Scans for OWASP Top 10 vulnerabilities
- Detects SQL injection, XSS, etc.
- Finds hardcoded secrets

**4. Performance Analyzer Agent**

- Calculates Big O complexity
- Identifies bottlenecks
- Suggests optimizations

**5. Test Generator Agent**

- Creates unit tests
- Generates edge cases
- Produces test fixtures

**6. Documentation Agent**

- Writes docstrings
- Adds inline comments
- Creates README sections

### Can I choose which agents to use?

Yes! You can select specific agents for each review. For example:

- Quick check: Syntax + Security only
- Full review: All 6 agents
- Pre-deployment: Security + Performance + Tests

### Does it actually fix the code?

Yes! It provides:

- **Refined code** with all suggestions applied
- **Diff view** showing what changed
- **Individual suggestions** you can apply selectively

### Can I customize the review criteria?

Yes (Enterprise plan, Phase 3+):

- Custom style guides
- Company-specific rules
- Framework-specific checks
- Custom agents

---

## 🔗 Integrations

### What integrations are available?

**Phase 1:**

- REST API
- Python SDK

**Phase 3:**

- Notion (database sync)
- GitHub (PR comments, Actions)
- VSCode/Cursor extension

**Phase 4+:**

- GitLab
- Bitbucket
- Jira/Linear
- Slack notifications
- JetBrains IDEs

### How does the Notion integration work?

1. Connect your Notion workspace
2. Choose a database to store reviews
3. Each review creates a new page with:
    - Original and refined code
    - Findings and scores
    - Diff view
    - Next steps

### Can I use it in my CI/CD pipeline?

Yes! Add to your GitHub Actions:

```yaml
- name: Code Alchemist Review
  uses: code-alchemist/action@v1
  with:
    api_key: $ secrets.CODE_ALCHEMIST_KEY 
    fail_on_critical: true
```

---

## 🚀 Getting Started

### How do I get started?

**Phase 0 (Current):**

1. Join the waitlist
2. Get access to Google AI Studio prototype
3. Start reviewing code!

**Phase 1+ (Planned):**

1. Sign up at [codealchemist.dev](http://codealchemist.dev)
2. Get your API key
3. Install CLI or IDE extension
4. Run your first review

### Is there a free trial?

Yes! **50 free reviews** when you sign up, no credit card required.

### Do I need to be a developer to use it?

Basically, yes. Code Alchemist is designed for developers who write code. However, technical managers and code reviewers can also benefit.

### Can I use it for homework/school projects?

Yes, but use it as a **learning tool**, not a replacement for learning. Understand the suggestions before applying them.

---

## 🤝 Support & Community

### How do I get help?

- **Documentation:** [docs.codealchemist.dev](http://docs.codealchemist.dev)
- **Email:** [support@codealchemist.dev](mailto:support@codealchemist.dev)
- **Discord:** Join our community
- **GitHub:** Report bugs and request features

### Can I contribute?

Yes! We're planning to open-source parts of the project in 2026.

### What if I find a bug?

1. Check if it's already reported on GitHub
2. If not, create a new issue with:
    - Steps to reproduce
    - Expected vs actual behavior
    - Code sample (if applicable)

### How often is it updated?

We ship updates:

- **Phase 0:** Weekly iterations
- **Phase 1+:** New features every 2 weeks
- **Bug fixes:** Within 24-48 hours

---

## 📊 Accuracy & Quality

### How accurate are the reviews?

**Overall accuracy:** ~90% of suggestions are rated "helpful" or better by users.

**By agent:**

- Syntax: 98% accuracy
- Security: 92% accuracy (8% false positives)
- Performance: 88% accuracy
- Tests: 85% accuracy (some test cases may be redundant)

### Does it make mistakes?

Yes, sometimes. That's why we provide:

- **Confidence scores** for each finding
- **Explanation** of why something was flagged
- **User feedback** to improve over time

### What if it suggests something wrong?

1. Don't blindly apply suggestions
2. Review each suggestion critically
3. Mark it as "Not helpful" so we can improve
4. You can always ignore suggestions

---

## 🌍 Availability

### Which regions is it available in?

**Phase 1:** US and EU

**Phase 2+:** Global (with region-specific deployments)

### Is there API rate limiting?

Yes:

- **Free:** 100 requests/hour
- **Pro:** 1,000 requests/hour
- **Enterprise:** 10,000 requests/hour (configurable)

### What's the uptime SLA?

- **Free/Pro:** 99.5% (best effort)
- **Enterprise:** 99.9% with financial penalties

---

## 💡 Use Cases

### When should I use Code Alchemist?

✅ **Good use cases:**

- Pre-commit code review
- Learning new frameworks
- Security audits
- Refactoring legacy code
- Onboarding new developers
- Open source PR review

❌ **Not ideal for:**

- Completely replacing human code review
- Auto-merging without human oversight
- Mission-critical production code (without human review)

---

**Didn't find your question?** Email [support@codealchemist.dev](mailto:support@codealchemist.dev) or join our Discord!