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
  confirmed_at timestamptz,
  forename text NOT NULL,
  lastname text NOT NULL,
  username text NOT NULL,
  password text NOT NULL,
  country_id int NOT NULL,
  email text NOT NULL
);

CREATE UNIQUE INDEX ux_users_username
ON users (username);

CREATE INDEX ix_users_country_id
ON users (country_id);

CREATE UNIQUE INDEX ux_users_email
ON users (email);

--
-- countries
--
CREATE SEQUENCE sq_countries;

CREATE TABLE countries
(
  id int NOT NULL DEFAULT nextval('sq_countries'),
  CONSTRAINT pk_countries PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  iso3166_a2 text NOT NULL,
  name text NOT NULL
);

CREATE UNIQUE INDEX ux_countries_iso3166_a2
ON countries (iso3166_a2);

--
-- vendors
--
CREATE SEQUENCE sq_vendors;

CREATE TABLE vendors
(
  id int NOT NULL DEFAULT nextval('sq_vendors'),
  CONSTRAINT pk_vendors PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  exid text NOT NULL,
  known_macs text[] NOT NULL,
  name text NOT NULL
);

CREATE UNIQUE INDEX ux_vendors_exid
ON vendors (exid);

CREATE INDEX vx_vendors_known_macs
ON vendors USING GIN (known_macs);

--
-- firmwares
--
CREATE SEQUENCE sq_firmwares;

CREATE TABLE firmwares
(
  id int NOT NULL DEFAULT nextval('sq_firmwares'),
  CONSTRAINT pk_firmwares PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  vendor_id int NOT NULL,
  name text NOT NULL,
  config json NOT NULL
);

CREATE INDEX ix_firmwares_vendor_id
ON firmwares (vendor_id);

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
  firmware_id int NOT NULL,
  external_uri text NOT NULL,
  internal_uri text NOT NULL,
  config json
);

CREATE INDEX ix_devices_firmware_id
ON devices (firmware_id);

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
  callback_uris text[] NOT NULL,
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
-- access_tokens_streams_rights
--
CREATE SEQUENCE sq_access_tokens_streams_rights;

CREATE TABLE access_tokens_streams_rights
(
  id int NOT NULL DEFAULT nextval('sq_access_tokens_streams_rights'),
  CONSTRAINT pk_access_tokens_streams_rights PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  token_id int NOT NULL,
  stream_id int NOT NULL,
  name text NOT NULL
);

CREATE UNIQUE INDEX ux_access_tokens_streams_rights_m_n
ON access_tokens_streams_rights (token_id, stream_id, name);

--
-- constraints
--
ALTER TABLE users
ADD CONSTRAINT fk_users_country_id
FOREIGN KEY (country_id) REFERENCES countries (id)
ON DELETE RESTRICT;

ALTER TABLE firmwares
ADD CONSTRAINT fk_firmwares_vendor_id
FOREIGN KEY (vendor_id) REFERENCES vendors (id)
ON DELETE CASCADE;

ALTER TABLE devices
ADD CONSTRAINT fk_devices_firmware_id
FOREIGN KEY (firmware_id) REFERENCES firmwares (id)
ON DELETE RESTRICT;

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

ALTER TABLE access_tokens_streams_rights
ADD CONSTRAINT fk_access_tokens_streams_rights_token_id
FOREIGN KEY (token_id) REFERENCES access_tokens (id)
ON DELETE CASCADE;

ALTER TABLE access_tokens_streams_rights
ADD CONSTRAINT fk_access_tokens_streams_rights_stream_id
FOREIGN KEY (stream_id) REFERENCES streams (id)
ON DELETE CASCADE;

