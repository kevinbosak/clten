-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sun May  3 12:43:51 2015
-- 
;
--
-- Table: access_level
--
CREATE TABLE "access_level" (
  "id" serial NOT NULL,
  "value" integer NOT NULL,
  "name" character varying(50) NOT NULL,
  "is_active" boolean DEFAULT '1' NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id")
);

;
--
-- Table: bot_command
--
CREATE TABLE "bot_command" (
  "id" serial NOT NULL,
  "room_id" bigint NOT NULL,
  "name" character varying(50) NOT NULL,
  "help_text" text,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id")
);

;
--
-- Table: agent
--
CREATE TABLE "agent" (
  "id" serial NOT NULL,
  "access_level_id" bigint NOT NULL,
  "groupme_id" character varying(50),
  "agent_name" character varying(50),
  "agent_level" integer,
  "first_name" character varying(50),
  "last_name" character varying(50),
  "play_area" character varying(255),
  "bio" text,
  "is_verified" boolean DEFAULT '0' NOT NULL,
  "gplus" character varying(100),
  "status" character varying(100) DEFAULT 'unregistered' NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "agent_groupme_id_key" UNIQUE ("groupme_id")
);
CREATE INDEX "agent_idx_access_level_id" on "agent" ("access_level_id");

;
--
-- Table: room
--
CREATE TABLE "room" (
  "id" serial NOT NULL,
  "name" character varying(200) NOT NULL,
  "access_level_id" bigint NOT NULL,
  "topic" character varying(200) NOT NULL,
  "image_url" character varying(200),
  "groupme_id" character varying NOT NULL,
  "bot_id" character varying(50),
  "groupme_bot_token" character varying(50),
  "is_moderated" boolean DEFAULT '0' NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "room_groupme_id_key" UNIQUE ("groupme_id")
);
CREATE INDEX "room_idx_access_level_id" on "room" ("access_level_id");

;
--
-- Table: agent_google
--
CREATE TABLE "agent_google" (
  "id" serial NOT NULL,
  "agent_id" bigint NOT NULL,
  "google_sub" character varying(50) NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "agent_google_idx_agent_id" on "agent_google" ("agent_id");

;
--
-- Table: bot_room_command
--
CREATE TABLE "bot_room_command" (
  "id" serial NOT NULL,
  "room_id" bigint NOT NULL,
  "command_id" bigint NOT NULL,
  "mod_only" boolean DEFAULT '0' NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "bot_room_command_idx_command_id" on "bot_room_command" ("command_id");
CREATE INDEX "bot_room_command_idx_room_id" on "bot_room_command" ("room_id");

;
--
-- Table: chat_log
--
CREATE TABLE "chat_log" (
  "id" serial NOT NULL,
  "agent_id" bigint NOT NULL,
  "room_id" bigint NOT NULL,
  "message_id" bigint NOT NULL,
  "avatar_url" character varying(255),
  "message" text,
  "attachments" json,
  "hearted_by" text[] DEFAULT '{}',
  "message_time" timestamp NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "room_message_key" UNIQUE ("room_id", "message_id")
);
CREATE INDEX "chat_log_idx_agent_id" on "chat_log" ("agent_id");
CREATE INDEX "chat_log_idx_room_id" on "chat_log" ("room_id");
CREATE INDEX "message_id_key" on "chat_log" ("message_id");

;
--
-- Table: room_access
--
CREATE TABLE "room_access" (
  "id" serial NOT NULL,
  "room_id" bigint NOT NULL,
  "agent_id" bigint NOT NULL,
  "group_user_id" bigint,
  "time_added" timestamp,
  "is_member" boolean DEFAULT '1' NOT NULL,
  "can_search" boolean DEFAULT '1' NOT NULL,
  "is_mod" boolean DEFAULT '0' NOT NULL,
  "is_owner" boolean DEFAULT '0' NOT NULL,
  "time_created" timestamp NOT NULL,
  "time_updated" timestamp NOT NULL,
  PRIMARY KEY ("id"),
  CONSTRAINT "agent_room_access_key" UNIQUE ("agent_id", "room_id")
);
CREATE INDEX "room_access_idx_agent_id" on "room_access" ("agent_id");
CREATE INDEX "room_access_idx_room_id" on "room_access" ("room_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "agent" ADD CONSTRAINT "agent_fk_access_level_id" FOREIGN KEY ("access_level_id")
  REFERENCES "access_level" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "room" ADD CONSTRAINT "room_fk_access_level_id" FOREIGN KEY ("access_level_id")
  REFERENCES "access_level" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "agent_google" ADD CONSTRAINT "agent_google_fk_agent_id" FOREIGN KEY ("agent_id")
  REFERENCES "agent" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "bot_room_command" ADD CONSTRAINT "bot_room_command_fk_command_id" FOREIGN KEY ("command_id")
  REFERENCES "bot_command" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "bot_room_command" ADD CONSTRAINT "bot_room_command_fk_room_id" FOREIGN KEY ("room_id")
  REFERENCES "room" ("id") DEFERRABLE;

;
ALTER TABLE "chat_log" ADD CONSTRAINT "chat_log_fk_agent_id" FOREIGN KEY ("agent_id")
  REFERENCES "agent" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "chat_log" ADD CONSTRAINT "chat_log_fk_room_id" FOREIGN KEY ("room_id")
  REFERENCES "room" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "room_access" ADD CONSTRAINT "room_access_fk_agent_id" FOREIGN KEY ("agent_id")
  REFERENCES "agent" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "room_access" ADD CONSTRAINT "room_access_fk_room_id" FOREIGN KEY ("room_id")
  REFERENCES "room" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
