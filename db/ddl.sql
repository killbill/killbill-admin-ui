CREATE TABLE `kaui_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `kb_username` varchar(255) NOT NULL,
  `kb_session_id` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_kaui_users_on_kb_username` (`kb_username`)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_bin;

CREATE TABLE `kaui_tenants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `kb_tenant_id` varchar(255) DEFAULT NULL,
  `api_key` varchar(255) DEFAULT NULL,
  `api_secret` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `kaui_allowed_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `kb_username` varchar(255) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `kaui_allowed_users_idx` (`kb_username`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8;

CREATE TABLE `kaui_allowed_user_tenants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `kaui_allowed_user_id` int(11) DEFAULT NULL,
  `kaui_tenant_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `kaui_allowed_users_tenants_uniq` (`kaui_allowed_user_id`,`kaui_tenant_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

