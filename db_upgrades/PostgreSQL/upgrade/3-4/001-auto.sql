-- Convert schema '../db_upgrades/_source/deploy/3/001-auto.yml' to '../db_upgrades/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE room ADD COLUMN is_moderated boolean DEFAULT '0' NOT NULL;

;
ALTER TABLE room_access ADD COLUMN group_user_id bigint;

;

COMMIT;

