-- Convert schema '../db_upgrades/_source/deploy/7/001-auto.yml' to '../db_upgrades/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE access_level ADD COLUMN name character varying(50) NOT NULL;

;
ALTER TABLE room DROP CONSTRAINT room_fk_access_level_id;

;
ALTER TABLE room ADD CONSTRAINT room_fk_access_level_id FOREIGN KEY (access_level_id)
  REFERENCES access_level (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

