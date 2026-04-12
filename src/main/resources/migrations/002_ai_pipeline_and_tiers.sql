-- Migration 002: AI pipeline and tier system.
-- Safe to run on an existing jotpage database.

ALTER TABLE users
    ADD COLUMN tier ENUM('free','pro') NOT NULL DEFAULT 'free' AFTER avatar_url;

CREATE TABLE user_subscriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE,
    tier ENUM('free','pro') NOT NULL DEFAULT 'free',
    stripe_customer_id VARCHAR(255) NULL,
    stripe_subscription_id VARCHAR(255) NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE ai_jobs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    job_type ENUM('verbatim','study_notes','meeting_minutes','journal_entry','outline','custom') NOT NULL,
    status ENUM('pending','processing','complete','failed') NOT NULL DEFAULT 'pending',
    input_text MEDIUMTEXT NULL,
    output_text MEDIUMTEXT NULL,
    audio_file_path VARCHAR(512) NULL,
    custom_prompt TEXT NULL,
    error_message TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE usage_tracking (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    month_year VARCHAR(7) NOT NULL,
    pages_created INT NOT NULL DEFAULT 0,
    ai_jobs_run INT NOT NULL DEFAULT 0,
    audio_minutes_processed DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE KEY uk_user_month (user_id, month_year)
);
