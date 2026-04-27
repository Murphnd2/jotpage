---
name: Stripe Subscription Scaffolding (Planned)
description: Stripe billing is on the roadmap; scaffolding exists but is not wired — documents what's present and what's needed to complete the implementation.
type: project
---

# Stripe Subscription Scaffolding (Planned)

Status: scaffolded, not wired (as of 2026-04-27)

**Why:** Stripe-based subscriptions are planned; the scaffolding was committed deliberately so the data model is ready when billing work begins. Not dead code.

**How to apply:** When Stripe work starts, use the checklist below rather than building from scratch — the POJO, DAO, and table already exist.

## What exists

- `com.jotpage.model.Subscription` — POJO with stripeCustomerId, stripeSubscriptionId, expiresAt
- `com.jotpage.dao.SubscriptionDao` — findByUserId, createOrUpdate, isProUser
- `schema.sql` `user_subscriptions` table with Stripe columns

## What's missing

- Stripe SDK in pom.xml
- Webhook handler servlet
- Wire-up in TierCheck.isProUser
- Stripe API key in jotpage.properties
- Customer portal / checkout flow

## When implementing

- Add Stripe Java SDK to pom.xml
- Implement Stripe webhook receiver (verify signature, parse event, call SubscriptionDao.createOrUpdate)
- Update TierCheck.isProUser to check SubscriptionDao first, fall back to existing logic
- Document key rotation in project_secrets_rotation.md
- Test in Stripe test mode before going live

Resolves JYRNYL-OPEN-QUESTIONS.md item #3 (intent documented).
