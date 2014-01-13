--
-- _schema
--
CREATE TABLE _schema
(
  key text NOT NULL,
  value text NOT NULL,
  CONSTRAINT pk_schema PRIMARY KEY (key)
);

INSERT INTO _schema (key, value) VALUES ('VERSION', '0003');

-- get ready for new tables
ALTER TABLE streams RENAME TO streams_old;
ALTER TABLE streams_old RENAME CONSTRAINT pk_streams TO pk_streams_old;

--
-- streams
--
CREATE TABLE streams
(
  id int NOT NULL DEFAULT nextval('sq_streams'),
  CONSTRAINT pk_streams PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  name text NOT NULL,
  firmware_id int,
  owner_id int NOT NULL,
  is_public boolean NOT NULL,
  config json NOT NULL
);

DROP INDEX ix_streams_owner_id;
CREATE INDEX ix_streams_owner_id
ON streams (owner_id);

DROP INDEX ux_streams_name;
CREATE UNIQUE INDEX ux_streams_name
ON streams (name);

ALTER TABLE streams
ADD CONSTRAINT fk_streams_owner_id
FOREIGN KEY (owner_id) REFERENCES users (id)
ON DELETE RESTRICT;

ALTER TABLE streams
ADD CONSTRAINT fk_streams_firmware_id
FOREIGN KEY (firmware_id) REFERENCES firmwares (id)
ON DELETE RESTRICT;

ALTER TABLE access_tokens_streams_rights
DROP CONSTRAINT fk_access_tokens_streams_rights_stream_id;

ALTER TABLE access_tokens_streams_rights
ADD CONSTRAINT fk_access_tokens_streams_rights_stream_id
FOREIGN KEY (stream_id) REFERENCES streams (id)
ON DELETE CASCADE;

