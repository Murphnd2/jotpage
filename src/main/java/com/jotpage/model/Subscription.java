package com.jotpage.model;

import java.sql.Timestamp;

/**
 * Subscription record representing a user's billing state.
 *
 * Currently scaffolded for planned Stripe integration but NOT YET WIRED:
 * - No code path constructs or persists Subscription instances
 * - SubscriptionDao exists but is not called by any servlet
 * - TierCheck currently determines tier from User.getTier() and the
 *   pro.emails property, not from this class
 * - pom.xml does not include the Stripe SDK dependency
 *
 * When Stripe billing is implemented, this class becomes the bridge
 * between Stripe webhook events and the user_subscriptions table.
 *
 * See: JYRNYL-OPEN-QUESTIONS.md item #3
 */
public class Subscription {

    private long id;
    private long userId;
    private String tier = "free";
    private String stripeCustomerId;
    private String stripeSubscriptionId;
    private Timestamp expiresAt;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    public Subscription() {
    }

    public long getId() {
        return id;
    }

    public void setId(long id) {
        this.id = id;
    }

    public long getUserId() {
        return userId;
    }

    public void setUserId(long userId) {
        this.userId = userId;
    }

    public String getTier() {
        return tier;
    }

    public void setTier(String tier) {
        this.tier = tier;
    }

    public String getStripeCustomerId() {
        return stripeCustomerId;
    }

    public void setStripeCustomerId(String stripeCustomerId) {
        this.stripeCustomerId = stripeCustomerId;
    }

    public String getStripeSubscriptionId() {
        return stripeSubscriptionId;
    }

    public void setStripeSubscriptionId(String stripeSubscriptionId) {
        this.stripeSubscriptionId = stripeSubscriptionId;
    }

    public Timestamp getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(Timestamp expiresAt) {
        this.expiresAt = expiresAt;
    }

    public Timestamp getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
}
