-- Migration 005: add image_layers column to pages for image overlays.
-- Safe to run on an existing jotpage database.

ALTER TABLE pages ADD COLUMN image_layers MEDIUMTEXT NULL;
