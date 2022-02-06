USE kaui;

CREATE TABLE kaui_users (
  id serial unique,
  kb_username varchar(255) NOT NULL,
  kb_session_id varchar(255) DEFAULT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
CREATE UNIQUE INDEX index_kaui_users_on_kb_username ON kaui_users(kb_username);

CREATE TABLE kaui_tenants (
  id serial unique,
  name varchar(255) NOT NULL,
  kb_tenant_id varchar(255) DEFAULT NULL,
  api_key varchar(255) DEFAULT NULL,
  encrypted_api_secret varchar(255) DEFAULT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
CREATE UNIQUE INDEX kaui_tenants_kb_name ON kaui_tenants(name);
CREATE UNIQUE INDEX kaui_tenants_kb_tenant_id ON kaui_tenants(kb_tenant_id);
CREATE UNIQUE INDEX kaui_tenants_kb_api_key ON kaui_tenants(api_key);

CREATE TABLE kaui_allowed_users (
  id serial unique,
  kb_username varchar(255) DEFAULT NULL,
  description varchar(255) DEFAULT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
CREATE UNIQUE INDEX kaui_allowed_users_idx ON kaui_allowed_users(kb_username);

CREATE TABLE kaui_allowed_user_tenants (
  id serial unique,
  kaui_allowed_user_id bigint /*! unsigned */ DEFAULT NULL,
  kaui_tenant_id bigint /*! unsigned */ DEFAULT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id)
) /*! CHARACTER SET utf8 COLLATE utf8_bin */;
CREATE UNIQUE INDEX kaui_allowed_users_tenants_uniq ON kaui_allowed_user_tenants(kaui_allowed_user_id,kaui_tenant_id);

