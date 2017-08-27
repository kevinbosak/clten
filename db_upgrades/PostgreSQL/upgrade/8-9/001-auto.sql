-- Convert schema '../db_upgrades/_source/deploy/8/001-auto.yml' to '../db_upgrades/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "chat_log" (
  "id" serial NOT NULL,
  "agent_id" bigint NOT NULL,
  "room_id" bigint NOT NULL,
  "message_id" bigint NOT NULL,
  "message" text,
  "attachments" json,
  "hearted_by" text[] DEFAULT '{}',
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "chat_log_idx_agent_id" on "chat_log" ("agent_id");
CREATE INDEX "chat_log_idx_room_id" on "chat_log" ("room_id");

;
ALTER TABLE "chat_log" ADD CONSTRAINT "chat_log_fk_agent_id" FOREIGN KEY ("agent_id")
  REFERENCES "agent" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "chat_log" ADD CONSTRAINT "chat_log_fk_room_id" FOREIGN KEY ("room_id")
  REFERENCES "room" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

