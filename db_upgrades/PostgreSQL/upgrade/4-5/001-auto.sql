-- Convert schema '../db_upgrades/_source/deploy/4/001-auto.yml' to '../db_upgrades/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "agent_google" (
  "id" serial NOT NULL,
  "agent_id" bigint NOT NULL,
  "google_sub" bigint NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "agent_google_idx_agent_id" on "agent_google" ("agent_id");

;
ALTER TABLE "agent_google" ADD CONSTRAINT "agent_google_fk_agent_id" FOREIGN KEY ("agent_id")
  REFERENCES "agent" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE agent ADD COLUMN status character varying(100) DEFAULT 'unregistered' NOT NULL;

;
ALTER TABLE agent ALTER COLUMN groupme_id DROP NOT NULL;

;
ALTER TABLE agent ALTER COLUMN agent_name DROP NOT NULL;

;
ALTER TABLE agent ALTER COLUMN first_name DROP NOT NULL;

;

COMMIT;

