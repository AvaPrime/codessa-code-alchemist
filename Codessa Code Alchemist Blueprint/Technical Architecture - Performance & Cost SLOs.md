# Technical Architecture: Performance & Cost SLOs

## Overview
Defines measurable targets (SLOs), error budgets, and cost ceilings for the MVP and subsequent phases, with clear measurement and gating.

## SLO Targets (Phase 1 MVP)
- Latency (single-agent path): p95 < 5s, p99 < 10s
- Availability (end-to-end success): ≥ 99.0% monthly
- Error Budget: ≤ 0.5% failed requests per 30 days
- Throughput: ≥ 10 RPS sustained, ≥ 50 burst for 5 minutes
- Cost Ceiling: ≤ $500/month total; ≤ $0.02/request average

## Measurement Methodology
- Instrument per-request timers (start→response) and status codes
- Emit counters: requests_total, errors_total, costs_total_usd
- Record model version, prompt template ID, token counts
- Aggregate daily rollups; store weekly summaries for trending

## CI/CD Gating
- CI thresholds:
  - Unit tests coverage ≥ 50% for MVP modules
  - Static analysis and secret scan must pass
  - Review gate label (“significant-change”) enforces 24h hold when applied
- Pre-merge checks (required status checks): match workflows already configured

## Dashboards and Alerts
- Latency dashboard: p50/p95/p99; per-path breakdown
- Error rate dashboard: failures by cause (timeout, provider, validation)
- Cost dashboard: per-request and daily totals; ceiling vs actual
- Alerts:
  - p95 > 5s for 15 minutes
  - Error rate > 0.5% over 1 hour
  - Daily cost > $25 or monthly forecast > ceiling

## Escalation and Runbooks
- On alert breach, capture last 100 failing traces and inputs metadata
- Triage order: provider health → prompt/context size → infra saturation
- Rollback prompt changes or reduce context size if needed

## Revision Cadence
- Review SLOs monthly; adjust ceilings and targets based on usage
- Phase 2 introduces parallel agents; new SLOs will include aggregation

