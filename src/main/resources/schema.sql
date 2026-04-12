CREATE DATABASE IF NOT EXISTS jotpage CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE jotpage;

CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    google_id VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    avatar_url VARCHAR(512),
    tier ENUM('free','pro') NOT NULL DEFAULT 'free',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

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

-- The background_type ENUM still lists daily_calendar / monthly_calendar /
-- time_slot so that existing databases migrated via
-- 003_remove_calendar_templates.sql remain accepted by the schema. The
-- seed data below no longer creates system templates for those types.
CREATE TABLE page_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NULL,
    name VARCHAR(100) NOT NULL,
    background_type ENUM('blank','lined','dot_grid','graph','daily_calendar','monthly_calendar','time_slot','custom') NOT NULL DEFAULT 'blank',
    background_data MEDIUMTEXT NULL,
    immutable_on_close BOOLEAN NOT NULL DEFAULT FALSE,
    is_system BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE pages (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    page_type_id BIGINT NOT NULL,
    title VARCHAR(255) DEFAULT '',
    sort_order INT NOT NULL DEFAULT 0,
    ink_data JSON,
    text_layers JSON,
    is_closed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (page_type_id) REFERENCES page_types(id)
);

CREATE TABLE tags (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    name VARCHAR(100) NOT NULL,
    color VARCHAR(7) DEFAULT '#6c757d',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE KEY uk_user_tag (user_id, name)
);

CREATE TABLE page_tags (
    page_id BIGINT NOT NULL,
    tag_id BIGINT NOT NULL,
    PRIMARY KEY (page_id, tag_id),
    FOREIGN KEY (page_id) REFERENCES pages(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);

INSERT INTO page_types (user_id, name, background_type, immutable_on_close, is_system) VALUES
(NULL, 'Blank',    'blank',    FALSE, TRUE),
(NULL, 'Lined',    'lined',    FALSE, TRUE),
(NULL, 'Dot Grid', 'dot_grid', FALSE, TRUE),
(NULL, 'Graph',    'graph',    FALSE, TRUE);

CREATE USER IF NOT EXISTS 'jotpage'@'localhost' IDENTIFIED BY 'CHANGEME';
GRANT ALL PRIVILEGES ON jotpage.* TO 'jotpage'@'localhost';
FLUSH PRIVILEGES;
