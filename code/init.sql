-- Create extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create table people
DROP TABLE IF EXISTS people; -- Ensure clean state for init
CREATE TABLE people (
    id UUID PRIMARY KEY,
    nickname VARCHAR(32) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    birth_date DATE NOT NULL,
    stack TEXT[], -- Use PostgreSQL array type
    -- Regenerate search column to handle TEXT[] stack type correctly
    search TEXT GENERATED ALWAYS AS (
        LOWER(name) || ' ' || LOWER(nickname) || ' ' || COALESCE(LOWER(array_to_string(stack, ' ')), '') -- Convert array to string for search
    ) STORED
);

-- Create search index using GIN trigram on the generated search column
-- CREATE INDEX CONCURRENTLY IF NOT EXISTS people_search_idx ON people USING GIN (search gin_trgm_ops);
-- Removed CONCURRENTLY as it cannot run safely inside the transaction block of the init script.
CREATE INDEX IF NOT EXISTS people_search_idx ON people USING GIN (search gin_trgm_ops);

-- Note: The UNIQUE constraint on nickname will cause standard COPY to fail on duplicates.
-- The batch insert mechanism needs to handle this, e.g., using a temporary table and INSERT ... ON CONFLICT.

