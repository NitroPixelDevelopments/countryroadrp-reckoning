-- Country Road RP - Season 1: Reckoning Database Setup
-- Version: 1.1.0

-- Create main database if not exists
CREATE DATABASE IF NOT EXISTS `crp_reckoning` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `crp_reckoning`;

-- Player Security Profiles
CREATE TABLE IF NOT EXISTS `reckoning_player_profiles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `player_name` varchar(100) NOT NULL,
    `clearance_level` int(2) DEFAULT 0,
    `job_name` varchar(50) DEFAULT NULL,
    `job_rank` varchar(50) DEFAULT NULL,
    `suspicion_level` int(3) DEFAULT 0,
    `total_violations` int(5) DEFAULT 0,
    `first_seen` timestamp DEFAULT CURRENT_TIMESTAMP,
    `last_activity` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `flags` text DEFAULT NULL,
    `notes` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `citizenid` (`citizenid`),
    INDEX `idx_clearance` (`clearance_level`),
    INDEX `idx_suspicion` (`suspicion_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Security Event Logs
CREATE TABLE IF NOT EXISTS `reckoning_security_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `event_type` varchar(50) NOT NULL,
    `event_category` varchar(30) NOT NULL,
    `severity` enum('info','warning','alert','critical') DEFAULT 'info',
    `location_x` float DEFAULT NULL,
    `location_y` float DEFAULT NULL,
    `location_z` float DEFAULT NULL,
    `zone_name` varchar(100) DEFAULT NULL,
    `description` text NOT NULL,
    `metadata` json DEFAULT NULL,
    `timestamp` timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_event_type` (`event_type`),
    INDEX `idx_category` (`event_category`),
    INDEX `idx_severity` (`severity`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tunnel Access Records
CREATE TABLE IF NOT EXISTS `reckoning_tunnel_access` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `tunnel_zone` varchar(100) NOT NULL,
    `access_granted` boolean DEFAULT false,
    `entry_time` timestamp DEFAULT CURRENT_TIMESTAMP,
    `exit_time` timestamp NULL DEFAULT NULL,
    `duration_seconds` int(8) DEFAULT NULL,
    `clearance_used` int(2) DEFAULT NULL,
    `entry_coords` json DEFAULT NULL,
    `exit_coords` json DEFAULT NULL,
    `notes` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_tunnel_zone` (`tunnel_zone`),
    INDEX `idx_access_granted` (`access_granted`),
    INDEX `idx_entry_time` (`entry_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Blackline Events
CREATE TABLE IF NOT EXISTS `reckoning_blackline_events` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `event_type` enum('interrogation','memory_wipe','surveillance') NOT NULL,
    `status` enum('active','completed','timeout','cancelled') DEFAULT 'active',
    `start_time` timestamp DEFAULT CURRENT_TIMESTAMP,
    `end_time` timestamp NULL DEFAULT NULL,
    `duration_seconds` int(6) DEFAULT NULL,
    `location_coords` json DEFAULT NULL,
    `agent_count` int(2) DEFAULT NULL,
    `vehicles_spawned` int(2) DEFAULT NULL,
    `outcome` varchar(100) DEFAULT NULL,
    `notes` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_citizenid` (`citizenid`),
    INDEX `idx_event_type` (`event_type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_start_time` (`start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Resistance Activity
CREATE TABLE IF NOT EXISTS `reckoning_resistance_activity` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `activity_type` enum('broadcast','interception','exposure','recruitment') NOT NULL,
    `message` text DEFAULT NULL,
    `frequency` float DEFAULT NULL,
    `signal_strength` float DEFAULT NULL,
    `location_coords` json DEFAULT NULL,
    `participants` json DEFAULT NULL,
    `timestamp` timestamp DEFAULT CURRENT_TIMESTAMP,
    `duration_seconds` int(6) DEFAULT NULL,
    `success_level` enum('failed','partial','success','critical') DEFAULT 'success',
    `detected_by_security` boolean DEFAULT false,
    `metadata` json DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_activity_type` (`activity_type`),
    INDEX `idx_timestamp` (`timestamp`),
    INDEX `idx_detected` (`detected_by_security`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- NPC Agent Activities
CREATE TABLE IF NOT EXISTS `reckoning_npc_agents` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `agent_type` enum('civilian_disguise','operative','handler') NOT NULL,
    `spawn_location` varchar(100) NOT NULL,
    `spawn_coords` json NOT NULL,
    `status` enum('active','exposed','eliminated','recalled') DEFAULT 'active',
    `spawn_time` timestamp DEFAULT CURRENT_TIMESTAMP,
    `despawn_time` timestamp NULL DEFAULT NULL,
    `exposed_by_citizenid` varchar(50) DEFAULT NULL,
    `interactions_count` int(4) DEFAULT 0,
    `cover_blown_reason` varchar(200) DEFAULT NULL,
    `mission_objective` varchar(200) DEFAULT NULL,
    `metadata` json DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_agent_type` (`agent_type`),
    INDEX `idx_status` (`status`),
    INDEX `idx_spawn_time` (`spawn_time`),
    INDEX `idx_exposed_by` (`exposed_by_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Propaganda Broadcasts
CREATE TABLE IF NOT EXISTS `reckoning_propaganda` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `channel` enum('public','emergency','internal') NOT NULL,
    `message` text NOT NULL,
    `broadcast_time` timestamp DEFAULT CURRENT_TIMESTAMP,
    `message_type` enum('scheduled','manual','triggered') DEFAULT 'scheduled',
    `triggered_by_admin` varchar(50) DEFAULT NULL,
    `audience_count` int(5) DEFAULT NULL,
    `effectiveness_score` float DEFAULT NULL,
    `responses_logged` int(4) DEFAULT 0,
    `metadata` json DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_channel` (`channel`),
    INDEX `idx_broadcast_time` (`broadcast_time`),
    INDEX `idx_message_type` (`message_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Server Milestones
CREATE TABLE IF NOT EXISTS `reckoning_milestones` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `milestone_name` varchar(100) NOT NULL,
    `current_triggers` int(4) DEFAULT 0,
    `required_triggers` int(4) NOT NULL,
    `status` enum('inactive','active','completed') DEFAULT 'active',
    `first_trigger_time` timestamp NULL DEFAULT NULL,
    `completion_time` timestamp NULL DEFAULT NULL,
    `triggered_by` json DEFAULT NULL,
    `effects_applied` json DEFAULT NULL,
    `description` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `milestone_name` (`milestone_name`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Admin Actions Log
CREATE TABLE IF NOT EXISTS `reckoning_admin_actions` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `admin_citizenid` varchar(50) NOT NULL,
    `admin_name` varchar(100) NOT NULL,
    `action_type` varchar(50) NOT NULL,
    `target_citizenid` varchar(50) DEFAULT NULL,
    `target_name` varchar(100) DEFAULT NULL,
    `command_used` varchar(200) DEFAULT NULL,
    `parameters` json DEFAULT NULL,
    `result` enum('success','failed','partial') DEFAULT 'success',
    `timestamp` timestamp DEFAULT CURRENT_TIMESTAMP,
    `ip_address` varchar(45) DEFAULT NULL,
    `notes` text DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_admin_citizenid` (`admin_citizenid`),
    INDEX `idx_action_type` (`action_type`),
    INDEX `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- System Statistics
CREATE TABLE IF NOT EXISTS `reckoning_system_stats` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `stat_name` varchar(100) NOT NULL,
    `stat_value` decimal(12,2) DEFAULT 0,
    `stat_type` enum('counter','gauge','percentage','time') DEFAULT 'counter',
    `category` varchar(50) NOT NULL,
    `last_updated` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `metadata` json DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `stat_name` (`stat_name`),
    INDEX `idx_category` (`category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default milestones
INSERT INTO `reckoning_milestones` (`milestone_name`, `required_triggers`, `description`) VALUES
('ghost_division_deployment', 5, 'Deployment of Ghost Division forces - triggers server-wide lockdown'),
('resistance_discovery', 3, 'Discovery of resistance network - increases security presence'),
('blackline_exposure', 10, 'Exposure of Blackline Protocol - triggers memory wipe campaigns'),
('tunnel_compromise', 2, 'TRENCHGLASS tunnel system compromise - activates emergency protocols')
ON DUPLICATE KEY UPDATE
`required_triggers` = VALUES(`required_triggers`),
`description` = VALUES(`description`);

-- Insert default system statistics
INSERT INTO `reckoning_system_stats` (`stat_name`, `stat_value`, `stat_type`, `category`) VALUES
('total_players_tracked', 0, 'counter', 'players'),
('active_security_events', 0, 'gauge', 'security'),
('tunnel_access_attempts', 0, 'counter', 'tunnels'),
('blackline_events_total', 0, 'counter', 'blackline'),
('resistance_broadcasts', 0, 'counter', 'resistance'),
('propaganda_messages', 0, 'counter', 'propaganda'),
('agents_exposed', 0, 'counter', 'npc'),
('system_uptime_hours', 0, 'time', 'system'),
('average_suspicion_level', 0, 'gauge', 'players'),
('total_violations', 0, 'counter', 'security')
ON DUPLICATE KEY UPDATE
`stat_value` = VALUES(`stat_value`);

-- Create indexes for performance
CREATE INDEX idx_security_logs_recent ON reckoning_security_logs(timestamp) USING BTREE;
CREATE INDEX idx_player_activity ON reckoning_player_profiles(last_activity) USING BTREE;
CREATE INDEX idx_event_severity ON reckoning_security_logs(severity, timestamp) USING BTREE;

-- Create views for common queries
CREATE OR REPLACE VIEW `view_active_security_events` AS
SELECT 
    sl.*,
    pp.player_name,
    pp.clearance_level,
    pp.suspicion_level
FROM `reckoning_security_logs` sl
LEFT JOIN `reckoning_player_profiles` pp ON sl.citizenid = pp.citizenid
WHERE sl.timestamp >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY sl.timestamp DESC;

CREATE OR REPLACE VIEW `view_high_risk_players` AS
SELECT 
    pp.*,
    COUNT(sl.id) as recent_violations
FROM `reckoning_player_profiles` pp
LEFT JOIN `reckoning_security_logs` sl ON pp.citizenid = sl.citizenid 
    AND sl.timestamp >= DATE_SUB(NOW(), INTERVAL 7 DAY)
WHERE pp.suspicion_level > 50 OR pp.total_violations > 10
GROUP BY pp.id
ORDER BY pp.suspicion_level DESC, recent_violations DESC;

CREATE OR REPLACE VIEW `view_tunnel_activity_summary` AS
SELECT 
    tunnel_zone,
    COUNT(*) as total_attempts,
    SUM(CASE WHEN access_granted = 1 THEN 1 ELSE 0 END) as successful_access,
    SUM(CASE WHEN access_granted = 0 THEN 1 ELSE 0 END) as denied_access,
    AVG(duration_seconds) as avg_duration,
    MAX(entry_time) as last_activity
FROM `reckoning_tunnel_access`
WHERE entry_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY tunnel_zone
ORDER BY total_attempts DESC;

-- Stored procedures for common operations
DELIMITER //

CREATE PROCEDURE `UpdatePlayerSuspicion`(
    IN p_citizenid VARCHAR(50),
    IN p_change_amount INT,
    IN p_reason VARCHAR(200)
)
BEGIN
    DECLARE current_suspicion INT DEFAULT 0;
    
    -- Get current suspicion level
    SELECT suspicion_level INTO current_suspicion 
    FROM reckoning_player_profiles 
    WHERE citizenid = p_citizenid;
    
    -- Update suspicion level (clamp between 0 and 100)
    UPDATE reckoning_player_profiles 
    SET suspicion_level = GREATEST(0, LEAST(100, current_suspicion + p_change_amount)),
        last_activity = NOW()
    WHERE citizenid = p_citizenid;
    
    -- Log the change
    INSERT INTO reckoning_security_logs (
        citizenid, event_type, event_category, severity, description, metadata
    ) VALUES (
        p_citizenid, 'suspicion_change', 'system', 'info',
        CONCAT('Suspicion level changed by ', p_change_amount, ': ', p_reason),
        JSON_OBJECT('previous_level', current_suspicion, 'change', p_change_amount, 'new_level', current_suspicion + p_change_amount)
    );
END //

CREATE PROCEDURE `LogSecurityEvent`(
    IN p_citizenid VARCHAR(50),
    IN p_event_type VARCHAR(50),
    IN p_category VARCHAR(30),
    IN p_severity VARCHAR(20),
    IN p_description TEXT,
    IN p_location_x FLOAT,
    IN p_location_y FLOAT,
    IN p_location_z FLOAT,
    IN p_metadata JSON
)
BEGIN
    INSERT INTO reckoning_security_logs (
        citizenid, event_type, event_category, severity, description,
        location_x, location_y, location_z, metadata
    ) VALUES (
        p_citizenid, p_event_type, p_category, p_severity, p_description,
        p_location_x, p_location_y, p_location_z, p_metadata
    );
    
    -- Update player profile last activity
    UPDATE reckoning_player_profiles 
    SET last_activity = NOW()
    WHERE citizenid = p_citizenid;
    
    -- Increment total violations if this is a violation
    IF p_severity IN ('alert', 'critical') THEN
        UPDATE reckoning_player_profiles 
        SET total_violations = total_violations + 1
        WHERE citizenid = p_citizenid;
    END IF;
END //

DELIMITER ;

-- Grant permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE ON crp_reckoning.* TO 'fivem_user'@'%';

COMMIT;

-- Database setup complete
SELECT 'Country Road RP - Reckoning database setup completed successfully!' as status;
