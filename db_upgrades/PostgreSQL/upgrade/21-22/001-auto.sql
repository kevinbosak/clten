-- Convert schema '../db_upgrades/_source/deploy/21/001-auto.yml' to '../db_upgrades/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE access_level ADD COLUMN required_level integer DEFAULT 0 NOT NULL;

;

COMMIT;

