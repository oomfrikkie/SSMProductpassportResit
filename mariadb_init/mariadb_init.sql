-- ======================================
-- SCANNERS TABLE
-- ======================================
-- Ensure target database exists and is selected
CREATE DATABASE IF NOT EXISTS mariadb_testdb;
USE mariadb_testdb;

CREATE TABLE scanner (
    id VARCHAR(50) PRIMARY KEY,
    location VARCHAR(255) NOT NULL,
    description TEXT
);

-- ======================================
-- MATERIAL EVENT (TIME-SERIES TABLE)
-- ======================================
CREATE TABLE material_event (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    scanner_id VARCHAR(50) NOT NULL,
    product_id VARCHAR(50) NOT NULL,   -- Comes from Postgres
    material_id VARCHAR(50) NOT NULL,  -- Comes from Postgres
    quantity INT DEFAULT 1,            -- optional
    event_type ENUM('added', 'removed') DEFAULT 'added',
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (scanner_id) REFERENCES scanner(id)
);

-- ======================================
-- SAMPLE SCANNERS
-- ======================================
INSERT INTO scanner (id, location, description) VALUES
('SCN001', 'Factory Entrance', 'Main scanning gate'),
('SCN002', 'Assembly Line', 'Material loading station'),
('SCN003', 'Packaging Section', 'Final assembly scanner');

-- ======================================
-- SAMPLE MATERIAL EVENTS
-- ======================================
INSERT INTO material_event (scanner_id, product_id, material_id, quantity, event_type, scanned_at)
VALUES
('SCN002', 'P001', 'MAT001', 1, 'added', '2025-10-29 12:05:00'),
('SCN002', 'P001', 'MAT002', 1, 'added', '2025-10-29 12:06:00'),

('SCN002', 'P002', 'MAT003', 1, 'added', '2025-10-29 13:10:00'),
('SCN002', 'P002', 'MAT004', 1, 'added', '2025-10-29 13:12:00'),

('SCN002', 'P004', 'MAT006', 1, 'added', '2025-10-29 14:50:00');
