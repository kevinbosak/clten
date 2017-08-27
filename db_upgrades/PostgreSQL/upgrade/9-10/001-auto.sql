-- Convert schema '../db_upgrades/_source/deploy/9/001-auto.yml' to '../db_upgrades/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE agent ADD CONSTRAINT agent_groupme_id_key UNIQUE (groupme_id);

;
ALTER TABLE chat_log ADD COLUMN message_time timestamp NOT NULL;

;
CREATE INDEX message_id_key on chat_log (message_id);

;
ALTER TABLE chat_log ADD CONSTRAINT room_message_key UNIQUE (room_id, message_id);

;
ALTER TABLE room ADD CONSTRAINT room_groupme_id_key UNIQUE (groupme_id);

;

COMMIT;

