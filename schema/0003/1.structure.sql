--
-- _schema
--
CREATE TABLE _schema
(
  key text NOT NULL,
  value text NOT NULL,
  CONSTRAINT pk_schema PRIMARY KEY (key)
);

INSERT INTO _schema (key, value) VALUES
  ('VERSION', '0003');

