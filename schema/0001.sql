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
  external_ip text NOT NULL,
  internal_ip text NOT NULL
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
  owner_id int NOT NULL,
  device_id int NOT NULL,
  name text NOT NULL
);

CREATE INDEX ix_streams_owner_id
ON streams (owner_id);

CREATE INDEX ix_streams_device_id
ON streams (device_id);

CREATE UNIQUE INDEX ux_streams_name
ON streams (name);

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

