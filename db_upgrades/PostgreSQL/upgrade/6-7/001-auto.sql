-- Convert schema '../db_upgrades/_source/deploy/6/001-auto.yml' to '../db_upgrades/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE agent DROP CONSTRAINT agent_fk_access_level_id;

;
ALTER TABLE agent ADD CONSTRAINT agent_fk_access_level_id FOREIGN KEY (access_level_id)
  REFERENCES access_level (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

