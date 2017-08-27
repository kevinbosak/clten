-- Convert schema '../db_upgrades/_source/deploy/23/001-auto.yml' to '../db_upgrades/_source/deploy/24/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "drawing" (
  "id" serial NOT NULL,
  "name" character varying(100) NOT NULL,
  "owner_id" bigint NOT NULL,
  "map_data" json NOT NULL,
  "access_level_id" bigint NOT NULL,
  "center" point,
  "zoom_level" integer,
  "proposed_throw_time" timestamp,
  "is_moderated" boolean DEFAULT '0' NOT NULL,
  "is_visible" boolean DEFAULT '1' NOT NULL,
  "whitelist" integer[] DEFAULT ARRAY[]::integer[] NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "drawing_idx_access_level_id" on "drawing" ("access_level_id");
CREATE INDEX "drawing_idx_owner_id" on "drawing" ("owner_id");

;
ALTER TABLE "drawing" ADD CONSTRAINT "drawing_fk_access_level_id" FOREIGN KEY ("access_level_id")
  REFERENCES "access_level" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "drawing" ADD CONSTRAINT "drawing_fk_owner_id" FOREIGN KEY ("owner_id")
  REFERENCES "agent" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE room ADD COLUMN is_visible boolean DEFAULT '1' NOT NULL;

;
ALTER TABLE room ADD COLUMN whitelist integer[] DEFAULT ARRAY[]::integer[] NOT NULL;

;

COMMIT;

