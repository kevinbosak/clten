-- Convert schema '../db_upgrades/_source/deploy/15/001-auto.yml' to '../db_upgrades/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE room ADD COLUMN image_url character varying(200);

;

COMMIT;

