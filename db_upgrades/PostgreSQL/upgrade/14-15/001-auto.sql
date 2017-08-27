-- Convert schema '../db_upgrades/_source/deploy/14/001-auto.yml' to '../db_upgrades/_source/deploy/15/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE chat_log ADD COLUMN avatar_url character varying(255);

;

COMMIT;

