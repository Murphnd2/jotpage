ALTER TABLE ai_jobs
    ADD COLUMN input_tokens  INT NULL AFTER error_message,
    ADD COLUMN output_tokens INT NULL AFTER input_tokens;
