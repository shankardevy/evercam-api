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


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: access_rights; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE access_rights (
    id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    token_id integer NOT NULL,
    "right" text NOT NULL,
    camera_id integer,
    grantor_id integer,
    status integer DEFAULT 1 NOT NULL,
    snapshot_id integer,
    account_id integer,
    scope character varying(100)
);


--
-- Name: access_rights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE access_rights_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_rights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE access_rights_id_seq OWNED BY access_rights.id;


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
    user_id integer,
    client_id integer,
    request text NOT NULL,
    refresh text,
    grantor_id integer
);


--
-- Name: add_ons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE add_ons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: add_ons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE add_ons (
    id integer DEFAULT nextval('add_ons_id_seq'::regclass) NOT NULL,
    user_id integer NOT NULL,
    add_ons_name text NOT NULL,
    period text NOT NULL,
    add_ons_start_date timestamp with time zone NOT NULL,
    add_ons_end_date timestamp with time zone NOT NULL,
    status boolean NOT NULL,
    price double precision NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: billing; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE billing (
    id integer NOT NULL,
    user_id integer NOT NULL,
    timelapse integer,
    snapmail integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: billing_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE billing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: billing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE billing_id_seq OWNED BY billing.id;


--
-- Name: camera_activities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE camera_activities (
    id integer NOT NULL,
    camera_id integer NOT NULL,
    access_token_id integer,
    action text NOT NULL,
    done_at timestamp with time zone NOT NULL,
    ip inet,
    extra json
);


--
-- Name: camera_activities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE camera_activities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camera_activities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE camera_activities_id_seq OWNED BY camera_activities.id;


--
-- Name: camera_endpoints; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE camera_endpoints (
    id integer NOT NULL,
    camera_id integer,
    scheme text NOT NULL,
    host text NOT NULL,
    port integer NOT NULL
);


--
-- Name: camera_endpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE camera_endpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camera_endpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE camera_endpoints_id_seq OWNED BY camera_endpoints.id;


--
-- Name: camera_share_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE camera_share_requests (
    id integer NOT NULL,
    camera_id integer NOT NULL,
    user_id integer NOT NULL,
    key character varying(100) NOT NULL,
    email character varying(250) NOT NULL,
    status integer NOT NULL,
    rights character varying(1000) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: camera_share_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE camera_share_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camera_share_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE camera_share_requests_id_seq OWNED BY camera_share_requests.id;


--
-- Name: camera_shares; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE camera_shares (
    id integer NOT NULL,
    camera_id integer NOT NULL,
    user_id integer NOT NULL,
    sharer_id integer,
    kind character varying(50) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: camera_shares_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE camera_shares_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: camera_shares_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE camera_shares_id_seq OWNED BY camera_shares.id;


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
-- Name: cameras; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cameras (
    id integer DEFAULT nextval('sq_streams'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    exid text NOT NULL,
    owner_id integer NOT NULL,
    is_public boolean NOT NULL,
    config json NOT NULL,
    name text NOT NULL,
    last_polled_at timestamp with time zone DEFAULT now(),
    is_online boolean,
    timezone text,
    last_online_at timestamp with time zone DEFAULT now(),
    location geography(Point,4326),
    mac_address macaddr,
    model_id integer,
    discoverable boolean DEFAULT false NOT NULL,
    preview bytea,
    thumbnail_url text
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
    api_id text NOT NULL,
    callback_uris text[],
    api_key text,
    name text,
    settings text
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

CREATE TABLE countries (
    id integer DEFAULT nextval('sq_countries'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    iso3166_a2 text NOT NULL,
    name text NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    filename text NOT NULL
);


--
-- Name: snapshots; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE snapshots (
    id integer NOT NULL,
    camera_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    notes text,
    data bytea NOT NULL,
    is_public boolean DEFAULT false NOT NULL
);


--
-- Name: snapshots_new_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE snapshots_new_id_seq
    START WITH 35008544
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: snapshots_new_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE snapshots_new_id_seq OWNED BY snapshots.id;


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
-- Name: sq_devices; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE sq_devices
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


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
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id integer DEFAULT nextval('sq_users'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    firstname text NOT NULL,
    lastname text NOT NULL,
    username text NOT NULL,
    password text NOT NULL,
    country_id integer,
    confirmed_at timestamp with time zone,
    email text NOT NULL,
    reset_token text,
    token_expires_at timestamp without time zone,
    api_id text,
    api_key text,
    is_admin boolean DEFAULT false NOT NULL,
    stripe_customer_id text,
    billing_id text
);


--
-- Name: vendor_models; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE vendor_models (
    id integer DEFAULT nextval('sq_firmwares'::regclass) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    vendor_id integer NOT NULL,
    name text NOT NULL,
    config json NOT NULL,
    exid text DEFAULT ''::text NOT NULL,
    jpg_url text DEFAULT ''::text NOT NULL,
    h264_url text DEFAULT ''::text NOT NULL,
    mjpg_url text DEFAULT ''::text NOT NULL
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
-- Name: webhooks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE webhooks (
    id integer NOT NULL,
    camera_id integer NOT NULL,
    user_id integer NOT NULL,
    url text NOT NULL,
    exid text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


--
-- Name: webhooks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE webhooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webhooks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE webhooks_id_seq OWNED BY webhooks.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_rights ALTER COLUMN id SET DEFAULT nextval('access_rights_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY billing ALTER COLUMN id SET DEFAULT nextval('billing_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_activities ALTER COLUMN id SET DEFAULT nextval('camera_activities_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_endpoints ALTER COLUMN id SET DEFAULT nextval('camera_endpoints_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_share_requests ALTER COLUMN id SET DEFAULT nextval('camera_share_requests_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_shares ALTER COLUMN id SET DEFAULT nextval('camera_shares_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY snapshots ALTER COLUMN id SET DEFAULT nextval('snapshots_new_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY webhooks ALTER COLUMN id SET DEFAULT nextval('webhooks_id_seq'::regclass);


--
-- Name: access_rights_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_rights
    ADD CONSTRAINT access_rights_pkey PRIMARY KEY (id);


--
-- Name: add_ons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY add_ons
    ADD CONSTRAINT add_ons_pkey PRIMARY KEY (id);


--
-- Name: billing_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY billing
    ADD CONSTRAINT billing_pkey PRIMARY KEY (id);


--
-- Name: camera_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY camera_endpoints
    ADD CONSTRAINT camera_endpoints_pkey PRIMARY KEY (id);


--
-- Name: camera_share_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY camera_share_requests
    ADD CONSTRAINT camera_share_requests_pkey PRIMARY KEY (id);


--
-- Name: camera_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY camera_shares
    ADD CONSTRAINT camera_shares_pkey PRIMARY KEY (id);


--
-- Name: pk_access_tokens; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT pk_access_tokens PRIMARY KEY (id);


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
-- Name: pk_firmwares; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vendor_models
    ADD CONSTRAINT pk_firmwares PRIMARY KEY (id);


--
-- Name: pk_streams; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cameras
    ADD CONSTRAINT pk_streams PRIMARY KEY (id);


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
-- Name: schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (filename);


--
-- Name: webhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY webhooks
    ADD CONSTRAINT webhooks_pkey PRIMARY KEY (id);


--
-- Name: access_rights_camera_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX access_rights_camera_id_index ON access_rights USING btree (camera_id);


--
-- Name: access_rights_token_id_camera_id_right_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX access_rights_token_id_camera_id_right_index ON access_rights USING btree (token_id, camera_id, "right");


--
-- Name: access_rights_token_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX access_rights_token_id_index ON access_rights USING btree (token_id);


--
-- Name: camera_activities_camera_id_done_at_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX camera_activities_camera_id_done_at_index ON camera_activities USING btree (camera_id, done_at);


--
-- Name: camera_endpoints_camera_id_scheme_host_port_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX camera_endpoints_camera_id_scheme_host_port_index ON camera_endpoints USING btree (camera_id, scheme, host, port);


--
-- Name: camera_share_requests_camera_id_email_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX camera_share_requests_camera_id_email_index ON camera_share_requests USING btree (camera_id, email);


--
-- Name: camera_share_requests_key_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX camera_share_requests_key_index ON camera_share_requests USING btree (key);


--
-- Name: camera_shares_camera_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX camera_shares_camera_id_index ON camera_shares USING btree (camera_id);


--
-- Name: camera_shares_camera_id_user_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX camera_shares_camera_id_user_id_index ON camera_shares USING btree (camera_id, user_id);


--
-- Name: camera_shares_user_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX camera_shares_user_id_index ON camera_shares USING btree (user_id);


--
-- Name: cameras_mac_address_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX cameras_mac_address_index ON cameras USING btree (mac_address);


--
-- Name: ix_access_tokens_grantee_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_access_tokens_grantee_id ON access_tokens USING btree (client_id);


--
-- Name: ix_access_tokens_grantor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_access_tokens_grantor_id ON access_tokens USING btree (user_id);


--
-- Name: ix_firmwares_vendor_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_firmwares_vendor_id ON vendor_models USING btree (vendor_id);


--
-- Name: ix_streams_owner_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_streams_owner_id ON cameras USING btree (owner_id);


--
-- Name: ix_users_country_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX ix_users_country_id ON users USING btree (country_id);


--
-- Name: snapshots_new_created_at_camera_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX snapshots_new_created_at_camera_id_index ON snapshots USING btree (created_at, camera_id);


--
-- Name: users_api_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX users_api_id_index ON users USING btree (api_id);


--
-- Name: ux_access_tokens_request; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_access_tokens_request ON access_tokens USING btree (request);


--
-- Name: ux_clients_exid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_clients_exid ON clients USING btree (api_id);


--
-- Name: ux_countries_iso3166_a2; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_countries_iso3166_a2 ON countries USING btree (iso3166_a2);


--
-- Name: ux_streams_name; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX ux_streams_name ON cameras USING btree (exid);


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
-- Name: vendor_models_exid_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX vendor_models_exid_index ON vendor_models USING btree (exid);


--
-- Name: vx_vendors_known_macs; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX vx_vendors_known_macs ON vendors USING gin (known_macs);


--
-- Name: access_rights_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_rights
    ADD CONSTRAINT access_rights_account_id_fkey FOREIGN KEY (account_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: access_rights_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_rights
    ADD CONSTRAINT access_rights_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES cameras(id) ON DELETE CASCADE;


--
-- Name: access_rights_grantor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_rights
    ADD CONSTRAINT access_rights_grantor_id_fkey FOREIGN KEY (grantor_id) REFERENCES users(id);


--
-- Name: access_rights_token_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_rights
    ADD CONSTRAINT access_rights_token_id_fkey FOREIGN KEY (token_id) REFERENCES access_tokens(id) ON DELETE CASCADE;


--
-- Name: access_tokens_grantor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT access_tokens_grantor_id_fkey FOREIGN KEY (grantor_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: add_ons_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY add_ons
    ADD CONSTRAINT add_ons_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: billing_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY billing
    ADD CONSTRAINT billing_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: camera_activities_access_token_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_activities
    ADD CONSTRAINT camera_activities_access_token_id_fkey FOREIGN KEY (access_token_id) REFERENCES access_tokens(id) ON DELETE CASCADE;


--
-- Name: camera_activities_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_activities
    ADD CONSTRAINT camera_activities_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES cameras(id) ON DELETE CASCADE;


--
-- Name: camera_endpoints_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_endpoints
    ADD CONSTRAINT camera_endpoints_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES cameras(id) ON DELETE CASCADE;


--
-- Name: camera_share_requests_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_share_requests
    ADD CONSTRAINT camera_share_requests_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES cameras(id) ON DELETE CASCADE;


--
-- Name: camera_share_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_share_requests
    ADD CONSTRAINT camera_share_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: camera_shares_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_shares
    ADD CONSTRAINT camera_shares_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES cameras(id) ON DELETE CASCADE;


--
-- Name: camera_shares_sharer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_shares
    ADD CONSTRAINT camera_shares_sharer_id_fkey FOREIGN KEY (sharer_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- Name: camera_shares_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY camera_shares
    ADD CONSTRAINT camera_shares_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: cameras_model_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cameras
    ADD CONSTRAINT cameras_model_id_fkey FOREIGN KEY (model_id) REFERENCES vendor_models(id);


--
-- Name: fk_access_tokens_grantee_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT fk_access_tokens_grantee_id FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;


--
-- Name: fk_access_tokens_grantor_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT fk_access_tokens_grantor_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: fk_firmwares_vendor_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY vendor_models
    ADD CONSTRAINT fk_firmwares_vendor_id FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE;


--
-- Name: fk_streams_owner_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY cameras
    ADD CONSTRAINT fk_streams_owner_id FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: fk_users_country_id; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT fk_users_country_id FOREIGN KEY (country_id) REFERENCES countries(id) ON DELETE RESTRICT;


--
-- Name: snapshots_new_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY snapshots
    ADD CONSTRAINT snapshots_new_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES cameras(id) ON DELETE CASCADE;


--
-- Name: webhooks_camera_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY webhooks
    ADD CONSTRAINT webhooks_camera_id_fkey FOREIGN KEY (camera_id) REFERENCES cameras(id) ON DELETE CASCADE;


--
-- Name: webhooks_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY webhooks
    ADD CONSTRAINT webhooks_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

