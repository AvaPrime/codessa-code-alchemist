# Codessa Code Alchemist

Codessa Code Alchemist is a governance-first AI coding/review assistant project. The repository is provisioned with production-grade CI/CD, strict branch protections, standardized issue templates, and a 24-hour review gate for significant changes — all before feature implementation begins.

## Key Features
- Governance-first repository setup with strict quality gates
- CI workflows for tests, linting, static analysis, and security scanning
- Build and staging deploy workflow with artifact retention
- Review gate enforcing 24-hour window for `significant-change` PRs
- Structured issue templates, labels, milestone, and project tracking

## Project Status
- Foundation complete: CI/CD, branch protection, review gate, issue templates, labels, milestone, and validation issues
- Pending: GitHub Projects board linkage (manual setup recommended)

See `implementation_summary.md` for a detailed, time-stamped summary of all governance work.

## Getting Started

### Prerequisites
- GitHub account and access to `AvaPrime/codessa-code-alchemist`
- GitHub CLI (`gh`) authenticated: `gh auth status`
- Python `3.11+` (if Python components are added)
- Node.js `18+` (if Node components are added)

### Clone
```bash
git clone https://github.com/AvaPrime/codessa-code-alchemist.git
cd codessa-code-alchemist
```

### Local Setup (conditional)
- Python:
  - If `requirements.txt` or `pyproject.toml` exists:
    ```bash
    python -m venv .venv
    .\.venv\Scripts\activate  # Windows PowerShell
    pip install -r requirements.txt  # or: pip install -e .
    ```
- Node:
  - If `package.json` exists:
    ```bash
    npm install
    ```

## Development Workflow
- Branch naming: `feat/...`, `fix/...`, `chore/...`, `docs/...`
- Pull Requests:
  - Target `main`
  - Minimum 1 approving review required
  - Stale reviews dismissed on new commits
  - Admins must follow rules; linear history enforced
- Labels and Milestones:
  - Use `type:*`, `priority:*`, and `component:*` labels
  - Link issues to the "Validation & Readiness" milestone

## CI/CD Pipelines

### CI (`.github/workflows/ci.yml`)
- python-tests: pytest + coverage (gracefully skips if no Python)
- node-tests: npm test + coverage (skips if no Node)
- lint-python: black, isort, flake8, mypy
- lint-node: ESLint, Prettier
- static-analysis: Bandit, CodeQL
- security-scan: Trivy, Safety, npm audit

### Build & Deploy (`.github/workflows/build_deploy.yml`)
- build-production: conditional artifact build with retention
- deploy-staging: gated on `main`, uses `STAGING_DEPLOY_URL` secret

### Review Gate (`.github/workflows/review_gate.yml`)
- Enforces minimum 24-hour review window for PRs labeled `significant-change`

### Required Status Checks
Nine checks are enforced on `main` as required for merging, aligning with CI/Build/Review Gate jobs.

## Governance & Policies
- Branch Protection: no force pushes or deletions, linear history required
- Merge Strategies: squash and rebase enabled; merge commits disabled
- Review Process: 24h hold for significant change PRs via label gating
- Security: multiple scanners active; secret scanning to be added

## Documentation & Architecture
- MVP Scope: `Codessa Code Alchemist Blueprint/Appendix - Phase 1 MVP Scope.md`
- SLOs: `Codessa Code Alchemist Blueprint/Technical Architecture - Performance & Cost SLOs.md`
- Technical Architecture: `Codessa Code Alchemist Blueprint/Technical Architecture Documentation 9fd8e7c32668426e87ecaf37d5f268da.md`
- Implementation Summary: `implementation_summary.md`

## Project Board
Manual setup (recommended, ~5 minutes):
1. Open `https://github.com/AvaPrime/codessa-code-alchemist/projects`
2. New project → Board template → Name: `Validation & Governance`
3. Use default columns (Backlog, In Progress, Done)
4. Add the 10 validation issues to the project and set Status to Backlog

## Secrets (for CI/CD)
Set repository secrets when ready:
```bash
gh secret set SLACK_WEBHOOK_URL   # optional notifications
gh secret set STAGING_DEPLOY_URL  # required for staging deploy job
```
Future secrets may include: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, and AWS credentials.

## Contributing
- Use issue templates for bug/feature/task/security
- Follow labels and milestones
- Keep PRs small, well-described, and linked to issues
A full `CONTRIBUTING.md` will be added.

## Security Policy
Report vulnerabilities via issues labeled `security` or contact repository owner. A `SECURITY.md` will be added with disclosure guidelines.

## License
TBD.

## Roadmap Highlights
- Phase 1: Security sanitization, Redis rate limiting, model gateway, partial-failure aggregation
- Phase 2+: Parallel agents, advanced orchestration, performance regression testing, Dependabot/Renovate

---
For a detailed governance progress report and sprint plan, read `implementation_summary.md`.
