-- Convert schema '../db_upgrades/_source/deploy/18/001-auto.yml' to '../db_upgrades/_source/deploy/19/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "agent_meeting" (
  "id" serial NOT NULL,
  "agent1_id" bigint NOT NULL,
  "agent2_id" bigint NOT NULL,
  "status" character varying(50) DEFAULT 'proposed' NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "agent_ids_key" UNIQUE ("agent1_id", "agent2_id")
);
CREATE INDEX "agent_meeting_idx_agent1_id" on "agent_meeting" ("agent1_id");
CREATE INDEX "agent_meeting_idx_agent2_id" on "agent_meeting" ("agent2_id");

;
ALTER TABLE "agent_meeting" ADD CONSTRAINT "agent_meeting_fk_agent1_id" FOREIGN KEY ("agent1_id")
  REFERENCES "agent" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "agent_meeting" ADD CONSTRAINT "agent_meeting_fk_agent2_id" FOREIGN KEY ("agent2_id")
  REFERENCES "agent" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

