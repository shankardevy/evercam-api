--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: _schema; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE _schema (
    key text NOT NULL,
    value text NOT NULL
);


--
-- Name: sq_access_tokens; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_access_tokens
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_tokens; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_tokens (
    id integer DEFAULT nextval('sq_access_tokens'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    is_revoked boolean NOT NULL,
    grantor_id integer NOT NULL,
    grantee_id integer NOT NULL,
    request text NOT NULL,
    refresh text
);


--
-- Name: sq_access_tokens_streams_rights; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_access_tokens_streams_rights
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_tokens_streams_rights; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_tokens_streams_rights (
    id integer DEFAULT nextval('sq_access_tokens_streams_rights'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    token_id integer NOT NULL,
    stream_id integer NOT NULL,
    name text NOT NULL
);


--
-- Name: sq_clients; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_clients
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clients (
    id integer DEFAULT nextval('sq_clients'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    exid text NOT NULL,
    callback_uris text[] NOT NULL,
    secret text NOT NULL,
    name text NOT NULL
);


--
-- Name: sq_countries; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_countries
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--
\echo 'Creating table `countries`'

CREATE TABLE countries (
    id integer DEFAULT nextval('sq_countries'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    iso3166_a2 text NOT NULL,
    name text NOT NULL
);

\echo 'Added Ireland to table `countries`'

INSERT INTO "countries" ("iso3166_a2", "name") VALUES ('ie', 'Ireland');

--
-- Name: sq_devices; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_devices
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: devices; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE devices (
    id integer DEFAULT nextval('sq_devices'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    firmware_id integer,
    external_uri text NOT NULL,
    internal_uri text NOT NULL,
    config json
);


--
-- Name: sq_firmwares; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_firmwares
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: firmwares; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE firmwares (
    id integer DEFAULT nextval('sq_firmwares'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    vendor_id integer NOT NULL,
    name text NOT NULL,
    config json NOT NULL,
    known_models text[] NOT NULL
);


--
-- Name: sq_streams; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_streams
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sq_users; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_users
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sq_vendors; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_vendors
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: streams; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE streams (
    id integer DEFAULT nextval('sq_streams'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    firmware_id integer,
    owner_id integer NOT NULL,
    is_public boolean NOT NULL,
    config json NOT NULL
);


--
-- Name: streams_old; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE streams_old (
    id integer DEFAULT nextval('sq_streams'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    device_id integer NOT NULL,
    owner_id integer NOT NULL,
    snapshot_path text NOT NULL,
    is_public boolean NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer DEFAULT nextval('sq_users'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    forename text NOT NULL,
    lastname text NOT NULL,
    username text NOT NULL,
    password text NOT NULL,
    country_id integer NOT NULL,
    confirmed_at timestamp with time zone,
    email text NOT NULL
);


--
-- Name: vendors; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vendors (
    id integer DEFAULT nextval('sq_vendors'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    exid text NOT NULL,
    known_macs text[] NOT NULL,
    name text NOT NULL
);


--
-- Name: pk_access_tokens; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT pk_access_tokens PRIMARY KEY (id);


--
-- Name: pk_access_tokens_streams_rights; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_tokens_streams_rights
    ADD CONSTRAINT pk_access_tokens_streams_rights PRIMARY KEY (id);


--
-- Name: pk_clients; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clients
    ADD CONSTRAINT pk_clients PRIMARY KEY (id);


--
-- Name: pk_countries; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT pk_countries PRIMARY KEY (id);


--
-- Name: pk_devices; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY devices
    ADD CONSTRAINT pk_devices PRIMARY KEY (id);


--
-- Name: pk_firmwares; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY firmwares
    ADD CONSTRAINT pk_firmwares PRIMARY KEY (id);


--
-- Name: pk_schema; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY _schema
    ADD CONSTRAINT pk_schema PRIMARY KEY (key);


--
-- Name: pk_streams; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY streams
    ADD CONSTRAINT pk_streams PRIMARY KEY (id);


--
-- Name: pk_streams_old; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY streams_old
    ADD CONSTRAINT pk_streams_old PRIMARY KEY (id);


--
-- Name: pk_users; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT pk_users PRIMARY KEY (id);


--
-- Name: pk_vendors; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vendors
    ADD CONSTRAINT pk_vendors PRIMARY KEY (id);


--
-- Name: ix_access_tokens_grantee_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_access_tokens_grantee_id ON access_tokens USING btree (grantee_id);


--
-- Name: ix_access_tokens_grantor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_access_tokens_grantor_id ON access_tokens USING btree (grantor_id);


--
-- Name: ix_devices_firmware_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_devices_firmware_id ON devices USING btree (firmware_id);


--
-- Name: ix_firmwares_vendor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_firmwares_vendor_id ON firmwares USING btree (vendor_id);


--
-- Name: ix_streams_device_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_streams_device_id ON streams_old USING btree (device_id);


--
-- Name: ix_streams_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_streams_owner_id ON streams USING btree (owner_id);


--
-- Name: ix_users_country_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_users_country_id ON users USING btree (country_id);


--
-- Name: ux_access_tokens_request; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_access_tokens_request ON access_tokens USING btree (request);


--
-- Name: ux_access_tokens_streams_rights_m_n; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_access_tokens_streams_rights_m_n ON access_tokens_streams_rights USING btree (token_id, stream_id, name);


--
-- Name: ux_clients_exid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_clients_exid ON clients USING btree (exid);


--
-- Name: ux_countries_iso3166_a2; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_countries_iso3166_a2 ON countries USING btree (iso3166_a2);


--
-- Name: ux_streams_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_streams_name ON streams USING btree (name);


--
-- Name: ux_users_email; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_users_email ON users USING btree (email);


--
-- Name: ux_users_username; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_users_username ON users USING btree (username);


--
-- Name: ux_vendors_exid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_vendors_exid ON vendors USING btree (exid);


--
-- Name: vx_vendors_known_macs; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX vx_vendors_known_macs ON vendors USING gin (known_macs);


--
-- Name: fk_access_tokens_grantee_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT fk_access_tokens_grantee_id FOREIGN KEY (grantee_id) REFERENCES clients(id) ON DELETE CASCADE;


--
-- Name: fk_access_tokens_grantor_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT fk_access_tokens_grantor_id FOREIGN KEY (grantor_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: fk_access_tokens_streams_rights_stream_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens_streams_rights
    ADD CONSTRAINT fk_access_tokens_streams_rights_stream_id FOREIGN KEY (stream_id) REFERENCES streams(id) ON DELETE CASCADE;


--
-- Name: fk_access_tokens_streams_rights_token_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens_streams_rights
    ADD CONSTRAINT fk_access_tokens_streams_rights_token_id FOREIGN KEY (token_id) REFERENCES access_tokens(id) ON DELETE CASCADE;


--
-- Name: fk_devices_firmware_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY devices
    ADD CONSTRAINT fk_devices_firmware_id FOREIGN KEY (firmware_id) REFERENCES firmwares(id) ON DELETE RESTRICT;


--
-- Name: fk_firmwares_vendor_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY firmwares
    ADD CONSTRAINT fk_firmwares_vendor_id FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE;


--
-- Name: fk_streams_device_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY streams_old
    ADD CONSTRAINT fk_streams_device_id FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE RESTRICT;


--
-- Name: fk_streams_firmware_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY streams
    ADD CONSTRAINT fk_streams_firmware_id FOREIGN KEY (firmware_id) REFERENCES firmwares(id) ON DELETE RESTRICT;


--
-- Name: fk_streams_owner_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY streams_old
    ADD CONSTRAINT fk_streams_owner_id FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: fk_streams_owner_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY streams
    ADD CONSTRAINT fk_streams_owner_id FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE RESTRICT;


--
-- Name: fk_users_country_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_users_country_id FOREIGN KEY (country_id) REFERENCES countries(id) ON DELETE RESTRICT;


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

