-- Convert schema '../db_upgrades/_source/deploy/20/001-auto.yml' to '../db_upgrades/_source/deploy/21/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE access_level ADD COLUMN required_mets integer DEFAULT 0 NOT NULL;

;
ALTER TABLE access_level ADD COLUMN met_access_level_id bigint;

;
CREATE INDEX access_level_idx_met_access_level_id on access_level (met_access_level_id);

;
ALTER TABLE access_level ADD CONSTRAINT access_level_fk_met_access_level_id FOREIGN KEY (met_access_level_id)
  REFERENCES access_level (id) DEFERRABLE;

;

COMMIT;

