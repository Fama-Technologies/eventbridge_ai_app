-- Migration: Add working_hours to vendor_profiles
-- Description: Adds a JSONB column to store flexible working hours (startTime, endTime, etc.)
-- Author: Antigravity AI

ALTER TABLE vendor_profiles 
ADD COLUMN IF NOT EXISTS working_hours JSONB DEFAULT '{}'::jsonb;

-- Optional: Index for performance if querying by hours frequently
CREATE INDEX IF NOT EXISTS idx_vendor_working_hours ON vendor_profiles USING GIN (working_hours);

COMMENT ON COLUMN vendor_profiles.working_hours IS 'Stores vendor business hours in JSON format (e.g., {"startTime": "08:00", "endTime": "18:00"})';
