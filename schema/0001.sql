--
-- users
--
CREATE SEQUENCE sq_users;

CREATE TABLE users
(
  id int NOT NULL DEFAULT nextval('sq_users'),
  CONSTRAINT pk_users PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  forename text NOT NULL,
  lastname text NOT NULL,
  username text NOT NULL,
  password text NOT NULL,
  email text NOT NULL
);

CREATE UNIQUE INDEX ux_users_username
ON users (username);

CREATE UNIQUE INDEX ux_users_email
ON users (email);

--
-- devices
--
CREATE SEQUENCE sq_devices;

CREATE TABLE devices
(
  id int NOT NULL DEFAULT nextval('sq_devices'),
  CONSTRAINT pk_devices PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  external_uri text NOT NULL,
  internal_uri text NOT NULL,
  username text NOT NULL,
  password text NOT NULL
);

--
-- streams
--
CREATE SEQUENCE sq_streams;

CREATE TABLE streams
(
  id int NOT NULL DEFAULT nextval('sq_streams'),
  CONSTRAINT pk_streams PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  name text NOT NULL,
  device_id int NOT NULL,
  owner_id int NOT NULL,
  snapshot_path text NOT NULL,
  is_public boolean NOT NULL
);

CREATE INDEX ix_streams_owner_id
ON streams (owner_id);

CREATE INDEX ix_streams_device_id
ON streams (device_id);

CREATE UNIQUE INDEX ux_streams_name
ON streams (name);

--
-- clients
--
CREATE SEQUENCE sq_clients;

CREATE TABLE clients
(
  id int NOT NULL DEFAULT nextval('sq_clients'),
  CONSTRAINT pk_clients PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  exid text NOT NULL,
  secret text NOT NULL,
  name text NOT NULL
);

CREATE UNIQUE INDEX ux_clients_exid
ON clients (exid);

--
-- access_tokens
--
CREATE SEQUENCE sq_access_tokens;

CREATE TABLE access_tokens
(
  id int NOT NULL DEFAULT nextval('sq_access_tokens'),
  CONSTRAINT pk_access_tokens PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at timestamptz NOT NULL,
  is_revoked boolean NOT NULL,
  grantor_id int NOT NULL,
  grantee_id int NOT NULL,
  request text NOT NULL,
  refresh text
);

CREATE INDEX ix_access_tokens_grantor_id
ON access_tokens (grantor_id);

CREATE INDEX ix_access_tokens_grantee_id
ON access_tokens (grantee_id);

CREATE UNIQUE INDEX ux_access_tokens_request
ON access_tokens (request);

--
-- constraints
--
ALTER TABLE streams
ADD CONSTRAINT fk_streams_owner_id
FOREIGN KEY (owner_id) REFERENCES users (id)
ON DELETE CASCADE;

ALTER TABLE streams
ADD CONSTRAINT fk_streams_device_id
FOREIGN KEY (device_id) REFERENCES devices (id)
ON DELETE RESTRICT;

ALTER TABLE access_tokens
ADD CONSTRAINT fk_access_tokens_grantor_id
FOREIGN KEY (grantor_id) REFERENCES users (id)
ON DELETE CASCADE;

ALTER TABLE access_tokens
ADD CONSTRAINT fk_access_tokens_grantee_id
FOREIGN KEY (grantee_id) REFERENCES clients (id)
ON DELETE CASCADE;

