-- cleanup old unused tables
DROP TABLE devices CASCADE;
DROP TABLE streams_old CASCADE;

-- rename streams as cameras
ALTER TABLE streams RENAME TO cameras;

-- update camera rights table
ALTER TABLE access_tokens_streams_rights RENAME TO camera_rights;
ALTER TABLE camera_rights DROP COLUMN name;
ALTER TABLE camera_rights DROP COLUMN stream_id;
ALTER TABLE camera_rights DROP COLUMN token_id;

ALTER TABLE camera_rights ADD COLUMN name text NOT NULL;
ALTER TABLE camera_rights ADD COLUMN camera_id int NOT NULL;
ALTER TABLE camera_rights ADD COLUMN access_token_id int;
ALTER TABLE camera_rights ADD COLUMN user_id int;

CREATE UNIQUE INDEX ix_camera_rights_camera_id_access_token_id
ON camera_rights (camera_id, access_token_id, name);

CREATE UNIQUE INDEX ix_camera_rights_camera_id_user_id
ON camera_rights (camera_id, user_id, name);

ALTER TABLE camera_rights
ADD CONSTRAINT fk_camera_rights_camera_id
FOREIGN KEY (camera_id) REFERENCES cameras (id)
ON DELETE CASCADE;

ALTER TABLE camera_rights
ADD CONSTRAINT fk_camera_rights_access_token_id
FOREIGN KEY (access_token_id) REFERENCES access_tokens (id)
ON DELETE CASCADE;

ALTER TABLE camera_rights
ADD CONSTRAINT fk_camera_rights_user_id
FOREIGN KEY (user_id) REFERENCES users (id)
ON DELETE CASCADE;

