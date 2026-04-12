-- Migration 001: add sort_order column to pages for notebook ordering.
-- Safe to run on an existing jotpage database.

ALTER TABLE pages ADD COLUMN sort_order INT NOT NULL DEFAULT 0 AFTER title;

-- Initialise existing rows in created_at order per user so the first time
-- a user opens the dashboard, their pages are already in a stable sequence.
SET @row := 0;
SET @last_user := NULL;
UPDATE pages p
JOIN (
    SELECT id,
           CASE WHEN @last_user = user_id THEN @row := @row + 1
                ELSE @row := 0 END AS new_order,
           @last_user := user_id
    FROM pages
    ORDER BY user_id, created_at, id
) ordered ON ordered.id = p.id
SET p.sort_order = ordered.new_order;
