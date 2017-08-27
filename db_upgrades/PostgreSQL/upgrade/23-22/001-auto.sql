-- Convert schema '../db_upgrades/_source/deploy/23/001-auto.yml' to '../db_upgrades/_source/deploy/22/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "drawing" (
  "id" serial NOT NULL
);

;
ALTER TABLE bot_command DROP COLUMN shortcut;

;
ALTER TABLE bot_room_command DROP COLUMN alias;

;

COMMIT;

