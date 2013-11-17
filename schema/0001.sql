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

