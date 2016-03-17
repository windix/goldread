=begin

CREATE TABLE IF NOT EXISTS `lists` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `asin` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `type` (`type`)
) DEFAULT CHARSET=utf8;

=end

