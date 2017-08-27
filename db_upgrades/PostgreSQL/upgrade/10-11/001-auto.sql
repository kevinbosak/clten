-- Convert schema '../db_upgrades/_source/deploy/10/001-auto.yml' to '../db_upgrades/_source/deploy/11/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE room ADD COLUMN groupme_bot_token character varying(50);

;

COMMIT;

