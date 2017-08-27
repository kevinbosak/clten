-- Convert schema '../db_upgrades/_source/deploy/5/001-auto.yml' to '../db_upgrades/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE agent_google ALTER COLUMN google_sub TYPE character varying(50);

;

COMMIT;

