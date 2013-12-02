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
-- devices
--
CREATE SEQUENCE sq_devices;

CREATE TABLE devices
(
  id int NOT NULL DEFAULT nextval('sq_devices'),
  CONSTRAINT pk_devices PRIMARY KEY (id),
  created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
  vendor_id int NOT NULL,
  external_uri text NOT NULL,
  internal_uri text NOT NULL,
  username text NOT NULL,
  password text NOT NULL
);

CREATE INDEX ix_devices_vendor_id
ON devices (vendor_id);

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

ALTER TABLE devices
ADD CONSTRAINT fk_devices_vendor_id
FOREIGN KEY (vendor_id) REFERENCES vendors (id)
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

---
--- data
---
INSERT INTO countries (iso3166_a2, name) VALUES
  ('ad', 'Andorra'),
  ('ae', 'United Arab Emirates'),
  ('af', 'Afghanistan'),
  ('ag', 'Antigua and Barbuda'),
  ('ai', 'Anguilla'),
  ('al', 'Albania'),
  ('am', 'Armenia'),
  ('an', 'Netherlands Antilles'),
  ('ao', 'Angola'),
  ('aq', 'Antarctica'),
  ('ar', 'Argentina'),
  ('as', 'American Samoa'),
  ('at', 'Austria'),
  ('au', 'Australia'),
  ('aw', 'Aruba'),
  ('ax', 'Aland Islands'),
  ('az', 'Azerbaijan'),
  ('ba', 'Bosnia and Herzegovina'),
  ('bb', 'Barbados'),
  ('bd', 'Bangladesh'),
  ('be', 'Belgium'),
  ('bf', 'Burkina Faso'),
  ('bg', 'Bulgaria'),
  ('bh', 'Bahrain'),
  ('bi', 'Burundi'),
  ('bj', 'Benin'),
  ('bm', 'Bermuda'),
  ('bn', 'Brunei Darussalam'),
  ('bo', 'Bolivia'),
  ('br', 'Brazil'),
  ('bs', 'Bahamas'),
  ('bt', 'Bhutan'),
  ('bv', 'Bouvet Island'),
  ('bw', 'Botswana'),
  ('by', 'Belarus'),
  ('bz', 'Belize'),
  ('ca', 'Canada'),
  ('cc', 'Cocos (Keeling) Islands'),
  ('cd', 'Congo-Kinshasa'),
  ('cf', 'Central African Republic'),
  ('cg', 'Congo-Brazzaville'),
  ('ch', 'Switzerland'),
  ('ci', 'Côte d''Ivoire'),
  ('ck', 'Cook Islands'),
  ('cl', 'Chile'),
  ('cm', 'Cameroon'),
  ('cn', 'China'),
  ('co', 'Colombia'),
  ('cr', 'Costa Rica'),
  ('cu', 'Cuba'),
  ('cv', 'Cape Verde'),
  ('cx', 'Christmas Island'),
  ('cy', 'Cyprus'),
  ('cz', 'Czech Republic'),
  ('de', 'Germany'),
  ('dj', 'Djibouti'),
  ('dk', 'Denmark'),
  ('dm', 'Dominica'),
  ('do', 'Dominican Republic'),
  ('dz', 'Algeria'),
  ('ec', 'Ecuador'),
  ('ee', 'Estonia'),
  ('eg', 'Egypt'),
  ('eh', 'Western Sahara'),
  ('er', 'Eritrea'),
  ('es', 'Spain'),
  ('et', 'Ethiopia'),
  ('fi', 'Finland'),
  ('fj', 'Fiji'),
  ('fk', 'Falkland Islands'),
  ('fm', 'Micronesia'),
  ('fo', 'Faroe Islands'),
  ('fr', 'France'),
  ('ga', 'Gabon'),
  ('gb', 'United Kingdom'),
  ('gd', 'Grenada'),
  ('ge', 'Georgia'),
  ('gf', 'French Guiana'),
  ('gg', 'Guernsey'),
  ('gh', 'Ghana'),
  ('gi', 'Gibraltar'),
  ('gl', 'Greenland'),
  ('gm', 'Gambia'),
  ('gn', 'Guinea'),
  ('gp', 'Guadeloupe'),
  ('gq', 'Equatorial Guinea'),
  ('gr', 'Greece'),
  ('gs', 'South Georgia and The South Sandwich Islands'),
  ('gt', 'Guatemala'),
  ('gu', 'Guam'),
  ('gw', 'Guinea-Bissau'),
  ('gy', 'Guyana'),
  ('hk', 'Hong Kong'),
  ('hm', 'Heard Island and McDonald Islands'),
  ('hn', 'Honduras'),
  ('hr', 'Croatia'),
  ('ht', 'Haiti'),
  ('hu', 'Hungary'),
  ('id', 'Indonesia'),
  ('ie', 'Ireland'),
  ('il', 'Israel'),
  ('im', 'Isle of Man'),
  ('in', 'India'),
  ('io', 'British Indian Ocean Territory'),
  ('iq', 'Iraq'),
  ('ir', 'Iran'),
  ('is', 'Iceland'),
  ('it', 'Italy'),
  ('je', 'Jersey'),
  ('jm', 'Jamaica'),
  ('jo', 'Jordan'),
  ('jp', 'Japan'),
  ('ke', 'Kenya'),
  ('kg', 'Kyrgyzstan'),
  ('kh', 'Cambodia'),
  ('ki', 'Kiribati'),
  ('km', 'Comoros'),
  ('kn', 'Saint Kitts and Nevis'),
  ('kp', 'North Korea'),
  ('kr', 'South Korea'),
  ('kw', 'Kuwait'),
  ('ky', 'Cayman Islands'),
  ('kz', 'Kazakhstan'),
  ('la', 'Laos'),
  ('lb', 'Lebanon'),
  ('lc', 'Saint Lucia'),
  ('li', 'Liechtenstein'),
  ('lk', 'Sri Lanka'),
  ('lr', 'Liberia'),
  ('ls', 'Lesotho'),
  ('lt', 'Lithuania'),
  ('lu', 'Luxembourg'),
  ('lv', 'Latvia'),
  ('ly', 'Libyan Arab Jamahiriya'),
  ('ma', 'Morocco'),
  ('mc', 'Monaco'),
  ('md', 'Moldova'),
  ('me', 'Montenegro'),
  ('mg', 'Madagascar'),
  ('mh', 'Marshall Islands'),
  ('mk', 'Macedonia'),
  ('ml', 'Mali'),
  ('mm', 'Myanmar'),
  ('mn', 'Mongolia'),
  ('mo', 'Macao'),
  ('mp', 'Northern Mariana Islands'),
  ('mq', 'Martinique'),
  ('mr', 'Mauritania'),
  ('ms', 'Montserrat'),
  ('mt', 'Malta'),
  ('mu', 'Mauritius'),
  ('mv', 'Maldives'),
  ('mw', 'Malawi'),
  ('mx', 'Mexico'),
  ('my', 'Malaysia'),
  ('mz', 'Mozambique'),
  ('na', 'Namibia'),
  ('nc', 'New Caledonia'),
  ('ne', 'Niger'),
  ('nf', 'Norfolk Island'),
  ('ng', 'Nigeria'),
  ('ni', 'Nicaragua'),
  ('nl', 'Netherlands'),
  ('no', 'Norway'),
  ('np', 'Nepal'),
  ('nr', 'Nauru'),
  ('nu', 'Niue'),
  ('nz', 'New Zealand'),
  ('om', 'Oman'),
  ('pa', 'Panama'),
  ('pe', 'Peru'),
  ('pf', 'French Polynesia'),
  ('pg', 'Papua New Guinea'),
  ('ph', 'Philippines'),
  ('pk', 'Pakistan'),
  ('pl', 'Poland'),
  ('pm', 'Saint Pierre and Miquelon'),
  ('pn', 'Pitcairn'),
  ('pr', 'Puerto Rico'),
  ('ps', 'Palestinian Territory'),
  ('pt', 'Portugal'),
  ('pw', 'Palau'),
  ('py', 'Paraguay'),
  ('qa', 'Qatar'),
  ('re', 'Reunion'),
  ('ro', 'Romania'),
  ('rs', 'Serbia'),
  ('ru', 'Russian Federation'),
  ('rw', 'Rwanda'),
  ('sa', 'Saudi Arabia'),
  ('sb', 'Solomon Islands'),
  ('sc', 'Seychelles'),
  ('sd', 'Sudan'),
  ('se', 'Sweden'),
  ('sg', 'Singapore'),
  ('sh', 'Saint Helena'),
  ('si', 'Slovenia'),
  ('sj', 'Svalbard and Jan Mayen'),
  ('sk', 'Slovakia'),
  ('sl', 'Sierra Leone'),
  ('sm', 'San Marino'),
  ('sn', 'Senegal'),
  ('so', 'Somalia'),
  ('sr', 'Suriname'),
  ('st', 'Sao Tome and Principe'),
  ('sv', 'El Salvador'),
  ('sy', 'Syrian Arab Republic'),
  ('sz', 'Swaziland'),
  ('tc', 'Turks and Caicos Islands'),
  ('td', 'Chad'),
  ('tf', 'French Southern Territories'),
  ('tg', 'Togo'),
  ('th', 'Thailand'),
  ('tj', 'Tajikistan'),
  ('tk', 'Tokelau'),
  ('tl', 'Timor-leste'),
  ('tm', 'Turkmenistan'),
  ('tn', 'Tunisia'),
  ('to', 'Tonga'),
  ('tr', 'Turkey'),
  ('tt', 'Trinidad and Tobago'),
  ('tv', 'Tuvalu'),
  ('tw', 'Taiwan'),
  ('tz', 'Tanzania'),
  ('ua', 'Ukraine'),
  ('ug', 'Uganda'),
  ('um', 'United States Minor Outlying Islands'),
  ('us', 'United States'),
  ('uy', 'Uruguay'),
  ('uz', 'Uzbekistan'),
  ('va', 'Vatican City State'),
  ('vc', 'Saint Vincent and The Grenadines'),
  ('ve', 'Venezuela'),
  ('vg', 'Virgin Islands, British'),
  ('vi', 'Virgin Islands, U.S.'),
  ('vn', 'Viet Nam'),
  ('vu', 'Vanuatu'),
  ('wf', 'Wallis and Futuna'),
  ('ws', 'Samoa'),
  ('ye', 'Yemen'),
  ('yt', 'Mayotte'),
  ('za', 'South Africa'),
  ('zm', 'Zambia'),
  ('zw', 'Zimbabwe');

INSERT INTO vendors (exid, name, known_macs) VALUES
  ('abus', 'ABUS Security-Center', '{8C:11:CB}'),
  ('avigilon', 'Avigilon Corporation', '{00:18:85}'),
  ('avtech', 'AVTECH Corporation', '{00:0E:53}'),
  ('axis', 'Axis Communications', '{00:40:8C}'),
  ('dlink', 'D-Link Corporation', '{00:05:5D,00:0D:88,00:0F:3D,00:11:95,00:13:46,00:15:E9,00:17:9A,00:19:5B,00:1B:11,00:1C:F0,00:1E:58,00:21:91,00:22:B0,00:24:01,00:26:5A,14:D6:4D,1C:7E:E5,28:10:7B,34:08:04,5C:D9:98,78:54:2E,84:C9:B2,90:94:E4,AC:F1:DF,B8:A3:86,BC:F6:85,C8:BE:19,C8:D3:A3,CC:B2:55,F0:7D:68,FC:75:16}'),
  ('hikvision', 'Hikvision Digital Technology', '{00:0C:43,00:40:48,8C:E7:48}'),
  ('panasonic', 'Panasonic Communications', '{00:80:F0}'),
  ('tplink', 'TP-Link Technologies', '{54:E6:FC}'),
  ('ubiquiti', 'Ubiquiti Networks', '{00:27:22,04:18:D6,24:A4:3C,68:72:51,DC:9F:DB}'),
  ('vivotek', 'Vivotek', '{00:02:D1}'),
  ('ycam', 'Y-cam Solutions', '{00:0D:F0,00:A1:B0}');

