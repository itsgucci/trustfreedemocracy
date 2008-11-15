CREATE TABLE `comments` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(50) default '',
  `comment` text,
  `created_at` datetime NOT NULL,
  `commentable_id` int(11) NOT NULL default '0',
  `commentable_type` varchar(15) NOT NULL default '',
  `user_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `fk_comments_user` (`user_id`),
  CONSTRAINT `comments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

CREATE TABLE `district_residences` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) NOT NULL,
  `district_id` int(11) NOT NULL,
  `start_date` datetime NOT NULL,
  `end_date` datetime NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `districts` (
  `id` int(11) NOT NULL auto_increment,
  `parent_id` int(11) NOT NULL default '0',
  `name` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `parent_id` (`parent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=latin1;

CREATE TABLE `endorsements` (
  `id` int(11) NOT NULL auto_increment,
  `proposal_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `group_memberships` (
  `id` int(11) NOT NULL auto_increment,
  `group_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `role` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=latin1;

CREATE TABLE `groups` (
  `id` int(11) NOT NULL auto_increment,
  `district_id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `tagline` varchar(260) NOT NULL,
  `type` int(11) default NULL,
  `created_on` datetime NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=latin1;

CREATE TABLE `idea_versions` (
  `id` int(11) NOT NULL auto_increment,
  `idea_id` int(11) default NULL,
  `version` int(11) default NULL,
  `title` varchar(255) default NULL,
  `content` text,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `ideas` (
  `id` int(11) NOT NULL auto_increment,
  `public` tinyint(1) NOT NULL default '0',
  `district_id` int(11) NOT NULL,
  `title` varchar(255) default NULL,
  `content` text,
  `user_id` int(11) NOT NULL,
  `created_at` date NOT NULL,
  `version` int(11) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;

CREATE TABLE `legislations` (
  `id` int(11) NOT NULL auto_increment,
  `district_id` int(11) NOT NULL,
  `number` varchar(255) default NULL,
  `title` text,
  `full_text` text,
  `sponsor` text,
  `cosponsors` text,
  `actions` text,
  `summary` text,
  `committees` text,
  `related_bills` text,
  `amendments` text,
  `votes_count` int(11) default '0',
  `closing_time` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=latin1;

CREATE TABLE `mailing_lists` (
  `id` int(11) NOT NULL auto_increment,
  `email` varchar(255) default NULL,
  `zip` varchar(10) NOT NULL,
  `created_on` datetime default NULL,
  `active` tinyint(1) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `memberships` (
  `id` int(11) NOT NULL auto_increment,
  `group_id` int(11) default NULL,
  `user_id` int(11) default NULL,
  `role` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=latin1;

CREATE TABLE `page_relationships` (
  `id` int(11) NOT NULL auto_increment,
  `page_id` int(11) default NULL,
  `pagable_id` int(11) default NULL,
  `pagable_type` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=latin1;

CREATE TABLE `page_versions` (
  `id` int(11) NOT NULL auto_increment,
  `page_id` int(11) default NULL,
  `version` int(11) default NULL,
  `title` varchar(255) default NULL,
  `content` text,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=latin1;

CREATE TABLE `pages` (
  `id` int(11) NOT NULL auto_increment,
  `title` varchar(255) default NULL,
  `content` text,
  `version` int(11) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=latin1;

CREATE TABLE `proposals` (
  `id` int(11) NOT NULL auto_increment,
  `district_id` int(11) NOT NULL,
  `title` varchar(420) NOT NULL,
  `summary` varchar(680) NOT NULL,
  `content` text NOT NULL,
  `owner_id` int(11) NOT NULL,
  `endorsements_count` int(11) NOT NULL default '0',
  `status_code` tinyint(4) default NULL,
  `created_on` datetime NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;

CREATE TABLE `representatives` (
  `id` int(11) NOT NULL auto_increment,
  `district_id` int(11) default NULL,
  `first_name` varchar(255) default NULL,
  `last_name` varchar(255) default NULL,
  `office` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `schema_info` (
  `version` int(11) default NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE `staff` (
  `id` int(11) NOT NULL auto_increment,
  `representative_id` int(11) default NULL,
  `name` varchar(255) default NULL,
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `staff_taggings` (
  `id` int(11) NOT NULL auto_increment,
  `tag_id` int(11) default NULL,
  `taggable_id` int(11) default NULL,
  `taggable_type` varchar(255) default NULL,
  `user_id` int(11) NOT NULL,
  `created_at` datetime default NULL,
  `weight` int(5) NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `index_taggings_on_tag_id` (`tag_id`),
  KEY `index_taggings_on_taggable_id_and_taggable_type` (`taggable_id`,`taggable_type`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `support` (
  `id` int(11) NOT NULL auto_increment,
  `support` tinyint(1) NOT NULL default '1',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `taggings` (
  `id` int(11) NOT NULL auto_increment,
  `tag_id` int(11) default NULL,
  `taggable_id` int(11) default NULL,
  `taggable_type` varchar(255) default NULL,
  `user_id` int(11) NOT NULL,
  `created_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `index_taggings_on_tag_id` (`tag_id`),
  KEY `index_taggings_on_taggable_id_and_taggable_type` (`taggable_id`,`taggable_type`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=latin1;

CREATE TABLE `tags` (
  `id` int(10) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=25 DEFAULT CHARSET=latin1;

CREATE TABLE `users` (
  `id` int(11) NOT NULL auto_increment,
  `first_name` varchar(255) NOT NULL,
  `last_name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `zip` varchar(10) NOT NULL,
  `secure_password` varchar(40) NOT NULL,
  `created_on` datetime NOT NULL,
  `login` varchar(255) NOT NULL,
  `district_id` int(11) unsigned NOT NULL default '0',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

CREATE TABLE `votes` (
  `id` int(11) NOT NULL auto_increment,
  `legislation_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `for` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `legislation_id` (`legislation_id`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `votes_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `votes_ibfk_1` FOREIGN KEY (`legislation_id`) REFERENCES `legislations` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

INSERT INTO schema_info (version) VALUES (17)