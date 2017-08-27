-- Convert schema '../db_upgrades/_source/deploy/17/001-auto.yml' to '../db_upgrades/_source/deploy/18/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE room ALTER COLUMN groupme_id TYPE character varying;

;
ALTER TABLE room ALTER COLUMN bot_id TYPE character varying(50);

;

COMMIT;

