CREATE TABLE `kaui_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `kb_username` varchar(255) NOT NULL,
  `kb_session_id` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_kaui_users_on_kb_username` (`kb_username`)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_bin;
