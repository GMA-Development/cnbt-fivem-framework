-- CNBT Framework — Base schema
-- Run once against your MySQL database (oxmysql connection).
-- Column names use camelCase to match the framework's conventions.

CREATE TABLE IF NOT EXISTS `users` (
    `id`        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `license`   VARCHAR(64)     NOT NULL,
    `createdAt` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `users_license` (`license`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS `characters` (
    `id`        INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `userId`    INT UNSIGNED    NOT NULL,
    `citizenid` VARCHAR(16)     NOT NULL,
    `firstName` VARCHAR(32)     NOT NULL,
    `lastName`  VARCHAR(32)     NOT NULL,
    `dob`       VARCHAR(16)              DEFAULT NULL,
    `gender`    TINYINT                  DEFAULT 0,
    `money`     LONGTEXT,        -- JSON: { "cash": 0, "bank": 0 }
    `job`       LONGTEXT,        -- JSON: { "name": "...", "grade": 0 }
    `position`  LONGTEXT,        -- JSON: { "x":, "y":, "z":, "heading": }
    `metadata`  LONGTEXT,        -- JSON: free-form per-character data
    `createdAt` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `characters_citizenid` (`citizenid`),
    KEY `characters_userId` (`userId`),
    CONSTRAINT `characters_user_fk`
        FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;
