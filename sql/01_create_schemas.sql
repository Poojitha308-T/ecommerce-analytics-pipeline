
-- ============================================
-- E-COMMERCE ANALYTICS PIPELINE
-- Day 2: Database and Schema Setup
-- Database: ecommerce_analytics
-- ============================================

-- IMPORTANT:
-- Create and connect to the ecommerce_analytics
-- database before executing this script.

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS production;

-- Verify the schemas
SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN (
    'raw',
    'staging',
    'production'
)
ORDER BY schema_name;
