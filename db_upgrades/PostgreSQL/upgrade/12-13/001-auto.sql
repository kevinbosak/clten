-- Convert schema '../db_upgrades/_source/deploy/12/001-auto.yml' to '../db_upgrades/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE room_access ADD CONSTRAINT agent_room_access_key UNIQUE (agent_id, room_id);

;

COMMIT;

