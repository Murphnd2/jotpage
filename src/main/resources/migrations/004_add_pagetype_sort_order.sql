-- Migration 004: add sort_order column to page_types for user-defined ordering.
-- Safe to run on an existing jotpage database.

ALTER TABLE page_types ADD COLUMN sort_order INT NOT NULL DEFAULT 0;

-- Initialise existing rows: system templates keep their id order,
-- custom templates start after them ordered by created_at.
UPDATE page_types SET sort_order = id WHERE is_system = TRUE;

UPDATE page_types pt
JOIN (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, id) + 100 AS rn
    FROM page_types
    WHERE is_system = FALSE
) ordered ON ordered.id = pt.id
SET pt.sort_order = ordered.rn;
