-- Convert schema '../db_upgrades/_source/deploy/2/001-auto.yml' to '../db_upgrades/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE agent ADD COLUMN play_area character varying(255);

;
ALTER TABLE agent ADD COLUMN bio text;

;

COMMIT;

