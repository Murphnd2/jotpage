-- Migration 003: drop the Daily Calendar, Monthly Calendar, and Time-Slot
-- Schedule system page types. Existing pages that still point at these
-- templates are reassigned to the Blank template (id = 1) so the foreign
-- key constraint on pages.page_type_id doesn't block the delete.
--
-- Safe to run on an existing jotpage database.

USE jotpage;

-- 1) Reassign any pages currently using a calendar/schedule system template
--    to the Blank template. We match by background_type so the migration is
--    resilient to different auto-increment ids between environments, and
--    we constrain to is_system = TRUE so we don't touch user-owned custom
--    templates that happen to share a background_type value.
UPDATE pages
JOIN page_types ON pages.page_type_id = page_types.id
SET pages.page_type_id = (
    SELECT id FROM (
        SELECT id FROM page_types
        WHERE background_type = 'blank' AND is_system = TRUE
        ORDER BY id
        LIMIT 1
    ) AS blank_pt
)
WHERE page_types.is_system = TRUE
  AND page_types.background_type IN ('daily_calendar', 'monthly_calendar', 'time_slot');

-- 2) Delete the three system rows.
DELETE FROM page_types
WHERE is_system = TRUE
  AND background_type IN ('daily_calendar', 'monthly_calendar', 'time_slot');
