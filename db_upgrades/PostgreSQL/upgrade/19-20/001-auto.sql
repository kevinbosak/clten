-- Convert schema '../db_upgrades/_source/deploy/19/001-auto.yml' to '../db_upgrades/_source/deploy/20/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE agent_meeting DROP CONSTRAINT agent_ids_key;

;
ALTER TABLE agent_meeting DROP CONSTRAINT agent_meeting_fk_agent1_id;

;
ALTER TABLE agent_meeting DROP CONSTRAINT agent_meeting_fk_agent2_id;

;
DROP INDEX agent_meeting_idx_agent1_id;

;
DROP INDEX agent_meeting_idx_agent2_id;

;
ALTER TABLE agent_meeting DROP COLUMN agent1_id;

;
ALTER TABLE agent_meeting DROP COLUMN agent2_id;

;
ALTER TABLE agent_meeting ADD COLUMN initiating_agent_id bigint NOT NULL;

;
ALTER TABLE agent_meeting ADD COLUMN confirming_agent_id bigint NOT NULL;

;
CREATE INDEX agent_meeting_idx_confirming_agent_id on agent_meeting (confirming_agent_id);

;
CREATE INDEX agent_meeting_idx_initiating_agent_id on agent_meeting (initiating_agent_id);

;
ALTER TABLE agent_meeting ADD CONSTRAINT agent_ids_key UNIQUE (initiating_agent_id, confirming_agent_id);

;
ALTER TABLE agent_meeting ADD CONSTRAINT agent_meeting_fk_confirming_agent_id FOREIGN KEY (confirming_agent_id)
  REFERENCES agent (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE agent_meeting ADD CONSTRAINT agent_meeting_fk_initiating_agent_id FOREIGN KEY (initiating_agent_id)
  REFERENCES agent (id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;

COMMIT;

