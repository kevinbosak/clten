-- Convert schema '../db_upgrades/_source/deploy/11/001-auto.yml' to '../db_upgrades/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE agent ADD COLUMN agent_level integer;

;

COMMIT;

