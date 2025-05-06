#!/bin/bash

# Define paths for temporary batch files and lock file
BATCH_DIR="/tmp/rinha_batch"
mkdir -p "$BATCH_DIR"
BATCH_FILE="$BATCH_DIR/batch_data.tsv"
LOCK_FILE="$BATCH_DIR/batch.lock"
MAX_BATCH_SIZE=100 # Number of records to accumulate before forcing a batch insert

# Function to process the batch file using COPY FROM STDIN
function process_batch() {
    # Use flock for simple locking to prevent concurrent processing
    ( flock -x 200

        # Check if batch file exists and is not empty
        if [ -s "$BATCH_FILE" ]; then
            echo "Processing batch file: $BATCH_FILE" >&2

            # Use a temporary table to handle potential unique constraint violations
            TEMP_TABLE_NAME="temp_people_$$" # Use PID for uniqueness

            # Prepare SQL command: Create temp table, COPY, INSERT ON CONFLICT
            # Note: Stack needs careful handling for array literal format in COPY
            # Assuming stack is a single element array like {"Java"}
            COPY_SQL="\
            CREATE TEMP TABLE $TEMP_TABLE_NAME (LIKE people INCLUDING DEFAULTS);\
            COPY $TEMP_TABLE_NAME (id, nickname, name, birth_date, stack) FROM STDIN (FORMAT CSV, DELIMITER E'\\t', NULL '');\
            INSERT INTO people (id, nickname, name, birth_date, stack)\
            SELECT id, nickname, name, birth_date, stack FROM $TEMP_TABLE_NAME\
            ON CONFLICT (nickname) DO NOTHING;\
            DROP TABLE $TEMP_TABLE_NAME;"

            # Execute the COPY command, feeding the batch file content
            # Replace single quotes in stack array literal with double quotes if needed by COPY format
            sed -E "s/(\{)\'(.*)\'(\})/"\\{\\"\\2\\"\\}"/g" "$BATCH_FILE" | psql -h 127.0.0.1 -U postgres -d postgres -p 6432 -c "$COPY_SQL" >&2
            PSQL_COPY_STATUS=$?

            if [ $PSQL_COPY_STATUS -eq 0 ]; then
                echo "Batch processed successfully." >&2
                # Clear the batch file after successful processing
                > "$BATCH_FILE"
            else
                echo "Error processing batch. PSQL Status: $PSQL_COPY_STATUS. Batch file retained for inspection." >&2
                # Consider moving the failed batch file instead of just retaining
                # mv "$BATCH_FILE" "$BATCH_FILE.failed.$$"
            fi
        fi

    ) 200>"$LOCK_FILE"
}

# Function to handle POST /pessoas requests
function handle_POST_create() {
    if [ -z "$BODY" ]; then
        # Invalid request body
        RESPONSE=$(cat views/400.http)
        return
    fi

    # Validate JSON and extract fields using jq (requires jq to be installed)
    # Basic validation: check if essential fields exist and birth_date format
    if ! echo "$BODY" | jq -e ".apelido and .nome and .nascimento and (.nascimento | test(\"^[0-9]{4}-[0-9]{2}-[0-9]{2}$\"))" > /dev/null; then
        RESPONSE=$(cat views/422.http)
        return
    fi

    # Extract fields using jq
    UUID=$(cat /proc/sys/kernel/random/uuid)
    APELIDO=$(echo "$BODY" | jq -r ".apelido // \"\"")
    NOME=$(echo "$BODY" | jq -r ".nome // \"\"")
    NASCIMENTO=$(echo "$BODY" | jq -r ".nascimento // \"\"")
    # Handle stack: convert null or non-array to empty array, then format for COPY
    STACK_RAW=$(echo "$BODY" | jq -r ".stack // [] | if type == \"array\" then . else [] end | map(tostring) | join(\",\")")

    # Basic server-side validation (length checks)
    if [ ${#APELIDO} -gt 32 ] || [ ${#NOME} -gt 100 ]; then
        RESPONSE=$(cat views/422.http)
        return
    fi
    # Check if any stack element > 32 chars (simplistic check)
    IFS=',' read -ra STACK_ARRAY <<< "$STACK_RAW"
    for item in "${STACK_ARRAY[@]}"; do
        if [ ${#item} -gt 32 ]; then
            RESPONSE=$(cat views/422.http)
            return
        fi
    done

    # Format stack for PostgreSQL array literal in COPY (e.g., {"Java","Python"})
    STACK_COPY_FORMAT="{\"${STACK_RAW//,/\",\"}\"}"
    # Handle empty stack case
    if [ "$STACK_RAW" == "" ]; then
        STACK_COPY_FORMAT="{}"
    fi

    # Append data to the batch file (TSV format)
    # Use flock for file locking during append
    ( flock -x 200
        echo -e "$UUID\\t$APELIDO\\t$NOME\\t$NASCIMENTO\\t$STACK_COPY_FORMAT" >> "$BATCH_FILE"
        # Check batch size and trigger processing if needed
        LINE_COUNT=$(wc -l < "$BATCH_FILE")
        if [ $LINE_COUNT -ge $MAX_BATCH_SIZE ]; then
            # Trigger batch processing in the background to avoid blocking the request
            process_batch &
        fi
    ) 200>"$LOCK_FILE"

    # Always return 201 Created immediately after appending to batch
    # The actual insertion happens asynchronously
    RESPONSE=$(cat views/201.http | sed "s/{{uuid}}/$UUID/")
}

# Add a background process to periodically process the batch file
# This ensures data is inserted even if MAX_BATCH_SIZE is not reached frequently
( while true; do
    sleep 5 # Process batch every 5 seconds
    process_batch
  done
) & # Run in the background

