package com.jotpage.dao;

import com.jotpage.model.Subscription;
import com.jotpage.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;

public class SubscriptionDao {

    private static final String SELECT_COLUMNS =
            "SELECT id, user_id, tier, stripe_customer_id, stripe_subscription_id, "
                    + "expires_at, created_at, updated_at FROM user_subscriptions";

    public Subscription findByUserId(long userId) throws SQLException {
        String sql = SELECT_COLUMNS + " WHERE user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    public Subscription createOrUpdate(Subscription sub) throws SQLException {
        if (sub == null) return null;
        Subscription existing = findByUserId(sub.getUserId());
        if (existing == null) {
            String insert = "INSERT INTO user_subscriptions "
                    + "(user_id, tier, stripe_customer_id, stripe_subscription_id, expires_at) "
                    + "VALUES (?, ?, ?, ?, ?)";
            try (Connection conn = DbUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(insert, Statement.RETURN_GENERATED_KEYS)) {
                ps.setLong(1, sub.getUserId());
                ps.setString(2, sub.getTier() == null ? "free" : sub.getTier());
                setStringOrNull(ps, 3, sub.getStripeCustomerId());
                setStringOrNull(ps, 4, sub.getStripeSubscriptionId());
                setTimestampOrNull(ps, 5, sub.getExpiresAt());
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) {
                        sub.setId(keys.getLong(1));
                    }
                }
            }
        } else {
            String update = "UPDATE user_subscriptions SET tier = ?, stripe_customer_id = ?, "
                    + "stripe_subscription_id = ?, expires_at = ? WHERE user_id = ?";
            try (Connection conn = DbUtil.getConnection();
                 PreparedStatement ps = conn.prepareStatement(update)) {
                ps.setString(1, sub.getTier() == null ? "free" : sub.getTier());
                setStringOrNull(ps, 2, sub.getStripeCustomerId());
                setStringOrNull(ps, 3, sub.getStripeSubscriptionId());
                setTimestampOrNull(ps, 4, sub.getExpiresAt());
                ps.setLong(5, sub.getUserId());
                ps.executeUpdate();
            }
        }
        return findByUserId(sub.getUserId());
    }

    public boolean isProUser(long userId) throws SQLException {
        String sql = "SELECT tier, expires_at FROM user_subscriptions WHERE user_id = ?";
        try (Connection conn = DbUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return false;
                String tier = rs.getString("tier");
                if (!"pro".equals(tier)) return false;
                Timestamp expiresAt = rs.getTimestamp("expires_at");
                if (expiresAt == null) return true; // null = no expiry
                return expiresAt.getTime() > System.currentTimeMillis();
            }
        }
    }

    private Subscription mapRow(ResultSet rs) throws SQLException {
        Subscription s = new Subscription();
        s.setId(rs.getLong("id"));
        s.setUserId(rs.getLong("user_id"));
        s.setTier(rs.getString("tier"));
        s.setStripeCustomerId(rs.getString("stripe_customer_id"));
        s.setStripeSubscriptionId(rs.getString("stripe_subscription_id"));
        s.setExpiresAt(rs.getTimestamp("expires_at"));
        s.setCreatedAt(rs.getTimestamp("created_at"));
        s.setUpdatedAt(rs.getTimestamp("updated_at"));
        return s;
    }

    private void setStringOrNull(PreparedStatement ps, int idx, String value) throws SQLException {
        if (value == null) {
            ps.setNull(idx, Types.VARCHAR);
        } else {
            ps.setString(idx, value);
        }
    }

    private void setTimestampOrNull(PreparedStatement ps, int idx, Timestamp value) throws SQLException {
        if (value == null) {
            ps.setNull(idx, Types.TIMESTAMP);
        } else {
            ps.setTimestamp(idx, value);
        }
    }
}
