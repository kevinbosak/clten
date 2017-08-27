-- Convert schema '../db_upgrades/_source/deploy/16/001-auto.yml' to '../db_upgrades/_source/deploy/17/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE room ADD COLUMN bot_id integer;

;

COMMIT;

