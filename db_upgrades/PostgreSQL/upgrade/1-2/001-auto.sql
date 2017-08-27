-- Convert schema '../db_upgrades/_source/deploy/1/001-auto.yml' to '../db_upgrades/_source/deploy/2/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE access_level ADD COLUMN time_created timestamp NOT NULL;

;
ALTER TABLE access_level ADD COLUMN time_updated timestamp NOT NULL;

;
ALTER TABLE agent ADD COLUMN time_created timestamp NOT NULL;

;
ALTER TABLE agent ADD COLUMN time_updated timestamp NOT NULL;

;
ALTER TABLE bot_command ADD COLUMN time_created timestamp NOT NULL;

;
ALTER TABLE bot_command ADD COLUMN time_updated timestamp NOT NULL;

;
ALTER TABLE bot_room_command ADD COLUMN time_created timestamp NOT NULL;

;
ALTER TABLE bot_room_command ADD COLUMN time_updated timestamp NOT NULL;

;
ALTER TABLE room ADD COLUMN time_created timestamp NOT NULL;

;
ALTER TABLE room ADD COLUMN time_updated timestamp NOT NULL;

;
ALTER TABLE room_access ADD COLUMN time_created timestamp NOT NULL;

;
ALTER TABLE room_access ADD COLUMN time_updated timestamp NOT NULL;

;

COMMIT;

