-- SwapLoop solution database — sample users + stations
-- Target: MySQL 8.0+ or MariaDB 10.5+
-- Plaintext password for all sample users: password123
-- password_hash uses bcrypt (cost 10)
-- api_token is the opaque bearer token returned by POST /api/v1/auth/login
-- Auth needs only the users table (no sessions table).
--
-- Vehicle profile (mode-driven):
--   SWAPPABLE  -> battery_type required (SL-48, SL-60); connector_type NULL
--                current_battery_id = pack currently on the rider's bike
--   INTEGRATED -> connector_type required (GB-AC-48, GB-AC-60); battery_type NULL
--                current_battery_id NULL
-- Voltage is implied by the chosen type (no separate voltage_class column).
--
-- Station units:
--   SWAP_BAY  -> battery_type (SL-48 / SL-60); connector_type NULL
--   BIKE_BAY  -> connector_type (GB-AC-48 / GB-AC-60); battery_type NULL
-- On swap confirm: bay goes CHARGING with the returned pack; rider gets battery_out.

SET NAMES utf8mb4;
SET time_zone = '+08:00';
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `swaploop_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `swaploop_db`;

DROP TABLE IF EXISTS `services`;
DROP TABLE IF EXISTS `reservations`;
DROP TABLE IF EXISTS `station_units`;
DROP TABLE IF EXISTS `price_list`;
DROP TABLE IF EXISTS `stations`;
DROP TABLE IF EXISTS `users`;

CREATE TABLE `users` (
  `id` VARCHAR(64) NOT NULL PRIMARY KEY,
  `email` VARCHAR(255) NOT NULL,
  `password_hash` VARCHAR(255) NOT NULL,
  `api_token` VARCHAR(128) NOT NULL,
  `display_name` VARCHAR(160) NOT NULL,
  `role` VARCHAR(64) NOT NULL,
  `status` VARCHAR(64) NOT NULL,
  `battery_mode` VARCHAR(64) NULL,
  `battery_type` VARCHAR(64) NULL,
  `connector_type` VARCHAR(64) NULL,
  `current_battery_id` VARCHAR(64) NULL,
  `partner_id` VARCHAR(64) NULL,
  `created_at` TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY `uq_users_email` (`email`),
  UNIQUE KEY `uq_users_api_token` (`api_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `users` (
  `id`,
  `email`,
  `password_hash`,
  `api_token`,
  `display_name`,
  `role`,
  `status`,
  `battery_mode`,
  `battery_type`,
  `connector_type`,
  `current_battery_id`,
  `partner_id`
) VALUES
  (
    'rider-001',
    'lin.xiaoyu@swaploop.test',
    '$2y$10$0XcesstTUTFQHFTZmq7dRurfxcNzJCN1cVctbOYYzHdUkzmOl4blO',
    'sl_tok_rider-001',
    'Lin Xiaoyu',
    'RIDER',
    'ACTIVE',
    'SWAPPABLE',
    'SL-48',
    NULL,
    'battery-101',
    NULL
  ),
  (
    'rider-002',
    'chen.wei@swaploop.test',
    '$2y$10$0XcesstTUTFQHFTZmq7dRurfxcNzJCN1cVctbOYYzHdUkzmOl4blO',
    'sl_tok_rider-002',
    'Chen Wei',
    'RIDER',
    'ACTIVE',
    'INTEGRATED',
    NULL,
    'GB-AC-48',
    NULL,
    NULL
  ),
  (
    'rider-003',
    'zhao.min@swaploop.test',
    '$2y$10$0XcesstTUTFQHFTZmq7dRurfxcNzJCN1cVctbOYYzHdUkzmOl4blO',
    'sl_tok_rider-003',
    'Zhao Min',
    'RIDER',
    'ACTIVE',
    'SWAPPABLE',
    'SL-48',
    NULL,
    'battery-103',
    NULL
  ),
  (
    'rider-006',
    'sun.hao@swaploop.test',
    '$2y$10$0XcesstTUTFQHFTZmq7dRurfxcNzJCN1cVctbOYYzHdUkzmOl4blO',
    'sl_tok_rider-006',
    'Sun Hao',
    'RIDER',
    'SUSPENDED',
    'INTEGRATED',
    NULL,
    'GB-AC-60',
    NULL,
    NULL
  );

CREATE TABLE `stations` (
  `id` VARCHAR(64) NOT NULL PRIMARY KEY,
  `community_id` VARCHAR(64) NOT NULL,
  `name` VARCHAR(160) NOT NULL,
  `type` VARCHAR(64) NOT NULL,
  `lifecycle_state` VARCHAR(64) NOT NULL,
  `latitude` DECIMAL(10,6) NOT NULL,
  `longitude` DECIMAL(10,6) NOT NULL,
  `address` VARCHAR(255) NOT NULL,
  `service_radius_meters` INT NOT NULL,
  `opens_at` VARCHAR(8) NOT NULL,
  `closes_at` VARCHAR(8) NOT NULL,
  `suspension_reason` TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `stations` (
  `id`,
  `community_id`,
  `name`,
  `type`,
  `lifecycle_state`,
  `latitude`,
  `longitude`,
  `address`,
  `service_radius_meters`,
  `opens_at`,
  `closes_at`,
  `suspension_reason`
) VALUES
  (
    'station-001',
    'community-001',
    'Haitang Garden East Gate',
    'HYBRID',
    'ACTIVE',
    31.230800,
    121.471700,
    '88 Haitang Community Road',
    700,
    '00:00',
    '24:00',
    NULL
  ),
  (
    'station-002',
    'community-002',
    'Canal View Delivery Hub',
    'SWAP',
    'ACTIVE',
    31.235600,
    121.478400,
    '16 Canal View Road',
    600,
    '05:00',
    '23:30',
    NULL
  ),
  (
    'station-003',
    'community-003',
    'Morning Bridge Charging Court',
    'CHARGING',
    'ACTIVE',
    31.226200,
    121.465200,
    '5 Morning Bridge Lane',
    650,
    '06:00',
    '22:00',
    NULL
  ),
  (
    'station-004',
    'community-005',
    'South Gate Exchange',
    'HYBRID',
    'SUSPENDED',
    31.218700,
    121.482100,
    '201 South Gate Street',
    800,
    '00:00',
    '24:00',
    'Electrical inspection in progress'
  ),
  (
    'station-005',
    'community-005',
    'South Gate Night Hub',
    'SWAP',
    'ACTIVE',
    31.220100,
    121.480500,
    '178 South Gate Street',
    800,
    '17:00',
    '02:00',
    NULL
  );

CREATE TABLE `station_units` (
  `id` VARCHAR(64) NOT NULL PRIMARY KEY,
  `station_id` VARCHAR(64) NOT NULL,
  `unit_type` VARCHAR(64) NOT NULL,
  `label` VARCHAR(32) NOT NULL,
  `state` VARCHAR(64) NOT NULL,
  `battery_type` VARCHAR(64) NULL,
  `connector_type` VARCHAR(64) NULL,
  `current_battery_id` VARCHAR(64) NULL,
  `partner_reserved_for_id` VARCHAR(64) NULL,
  `blocked_reason` VARCHAR(160) NULL,
  KEY `idx_station_units_station_id` (`station_id`),
  CONSTRAINT `fk_station_units_station`
    FOREIGN KEY (`station_id`) REFERENCES `stations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `station_units` (
  `id`,
  `station_id`,
  `unit_type`,
  `label`,
  `state`,
  `battery_type`,
  `connector_type`,
  `current_battery_id`,
  `partner_reserved_for_id`,
  `blocked_reason`
) VALUES
  ('unit-001', 'station-001', 'SWAP_BAY', 'S01', 'READY', 'SL-48', NULL, 'battery-001', NULL, NULL),
  ('unit-002', 'station-001', 'SWAP_BAY', 'S02', 'RESERVED', 'SL-48', NULL, 'battery-002', NULL, NULL),
  ('unit-003', 'station-001', 'SWAP_BAY', 'S03', 'CHARGING', 'SL-60', NULL, 'battery-003', 'partner-001', NULL),
  ('unit-004', 'station-001', 'SWAP_BAY', 'S04', 'FAULTED', 'SL-48', NULL, NULL, NULL, NULL),
  ('unit-005', 'station-001', 'BIKE_BAY', 'B02', 'AVAILABLE', NULL, 'GB-AC-48', NULL, NULL, NULL),
  ('unit-006', 'station-001', 'BIKE_BAY', 'B03', 'CHARGING', NULL, 'GB-AC-48', NULL, NULL, NULL),
  ('unit-007', 'station-001', 'BIKE_BAY', 'B01', 'READY_FOR_COLLECTION', NULL, 'GB-AC-48', NULL, NULL, NULL),
  ('unit-008', 'station-002', 'SWAP_BAY', 'S01', 'CHARGING', 'SL-60', NULL, 'battery-010', 'partner-001', NULL),
  ('unit-009', 'station-002', 'SWAP_BAY', 'S02', 'READY', 'SL-48', NULL, 'battery-005', NULL, NULL),
  ('unit-010', 'station-002', 'SWAP_BAY', 'S03', 'QUARANTINED', 'SL-48', NULL, 'battery-006', NULL, NULL),
  ('unit-015', 'station-002', 'SWAP_BAY', 'S04', 'READY', 'SL-48', NULL, 'battery-008', NULL, NULL),
  ('unit-011', 'station-003', 'BIKE_BAY', 'B03', 'AVAILABLE', NULL, 'GB-AC-60', NULL, NULL, NULL),
  ('unit-012', 'station-003', 'BIKE_BAY', 'B01', 'AVAILABLE', NULL, 'GB-AC-48', NULL, NULL, NULL),
  ('unit-013', 'station-003', 'BIKE_BAY', 'B02', 'BLOCKED', NULL, 'GB-AC-48', NULL, NULL, 'SAFETY_CUTOFF'),
  ('unit-014', 'station-005', 'SWAP_BAY', 'S01', 'READY', 'SL-48', NULL, 'battery-007', NULL, NULL);

CREATE TABLE `price_list` (
  `price_code` VARCHAR(64) NOT NULL PRIMARY KEY,
  `service_type` VARCHAR(64) NOT NULL,
  `battery_type` VARCHAR(64) NULL,
  `connector_type` VARCHAR(64) NULL,
  `amount_yuan` INT NOT NULL,
  `active` TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `price_list`
  (`price_code`, `service_type`, `battery_type`, `connector_type`, `amount_yuan`, `active`)
VALUES
  ('SWAP_SL-48', 'SWAP', 'SL-48', NULL, 5, 1),
  ('SWAP_SL-60', 'SWAP', 'SL-60', NULL, 7, 1),
  ('CHARGE_GB-AC-48', 'CHARGING', NULL, 'GB-AC-48', 3, 1),
  ('CHARGE_GB-AC-60', 'CHARGING', NULL, 'GB-AC-60', 4, 1);

CREATE TABLE `services` (
  `id` VARCHAR(64) NOT NULL PRIMARY KEY,
  `type` VARCHAR(64) NOT NULL,
  `user_id` VARCHAR(64) NOT NULL,
  `station_id` VARCHAR(64) NOT NULL,
  `unit_id` VARCHAR(64) NOT NULL,
  `state` VARCHAR(64) NOT NULL,
  `battery_out_id` VARCHAR(64) NULL,
  `battery_in_id` VARCHAR(64) NULL,
  `partner_priority_applied` TINYINT(1) NOT NULL DEFAULT 0,
  `price_yuan` INT NULL,
  `price_code` VARCHAR(64) NULL,
  `created_at` DATETIME(3) NOT NULL,
  `expires_at` DATETIME(3) NOT NULL,
  `completed_at` DATETIME(3) NULL,
  `started_at` DATETIME(3) NULL,
  KEY `idx_services_user_state` (`user_id`, `state`),
  KEY `idx_services_unit` (`unit_id`),
  CONSTRAINT `fk_services_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `fk_services_station`
    FOREIGN KEY (`station_id`) REFERENCES `stations` (`id`),
  CONSTRAINT `fk_services_unit`
    FOREIGN KEY (`unit_id`) REFERENCES `station_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
