-- Convert schema '../db_upgrades/_source/deploy/22/001-auto.yml' to '../db_upgrades/_source/deploy/23/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE agent ADD COLUMN agreed_to_terms boolean DEFAULT '0' NOT NULL;

;
DROP TABLE drawing CASCADE;

;

COMMIT;

