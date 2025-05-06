#!/bin/bash

# Modified handler for Bash HTTP Gateway (BHG)

declare -A PARAMS # Use uppercase to avoid potential conflicts with env vars

function handleRequest_bhg() {
    # Data comes from environment variables and stdin set by BHG
    # REQUEST_METHOD, REQUEST_URI, QUERY_STRING, HTTP_CONTENT_LENGTH, etc.

    # Parse query string (if present)
    if [[ -n "$QUERY_STRING" ]]; then
        # Simple parsing for 't' parameter
        if [[ "$QUERY_STRING" == "t="* ]]; then
            PARAMS["term"]="${QUERY_STRING#t=}"
            # Basic URL decoding (replace %20 with space, etc. - needs improvement for full spec)
            PARAMS["term"]=$(echo -e "${PARAMS["term"]//%/\\x}")
        fi
    fi

    # Parse path parameter (UUID)
    # Example: /pessoas/uuid-goes-here
    PATH_PARAMETER_REGEX=".*\/pessoas\/(.*)"
    if [[ "$REQUEST_URI" =~ $PATH_PARAMETER_REGEX ]]; then
        PARAMS["id"]="${BASH_REMATCH[1]}"
        # Adjust REQUEST for routing comparison
        ROUTING_REQUEST="$REQUEST_METHOD /pessoas/:id"
    else
        # Remove query string for routing comparison
        ROUTING_REQUEST="$REQUEST_METHOD ${REQUEST_URI%%
?*}"
    fi

    # Read the request body from stdin if Content-Length is provided
    BODY=""
    if [[ -n "$HTTP_CONTENT_LENGTH" && "$HTTP_CONTENT_LENGTH" -gt 0 ]]; then
        # Ensure we don't read more than specified
        # Use timeout to prevent hanging if client sends less data than header indicates
        read -t 1 -N $HTTP_CONTENT_LENGTH BODY
        # Alternative using head, potentially safer:
        # BODY=$(head -c $HTTP_CONTENT_LENGTH)
    fi

    # Debugging output to stderr (will be logged by Docker)
    # echo "DEBUG [Bash]: Method=$REQUEST_METHOD, URI=$REQUEST_URI, Query=$QUERY_STRING, ID=${PARAMS["id"]}" >&2
    # echo "DEBUG [Bash]: Body Length=${#BODY}" >&2
    # echo "DEBUG [Bash]: Body=$BODY" >&2

    # Source handler functions
    # Ensure paths are correct relative to this script's location in the container (/app)
    source /app/app/search.bash
    source /app/app/count.bash
    source /app/app/find.bash
    source /app/app/create.bash # Assumes create.bash is adapted for batching
    source /app/app/not-found.bash

    # Route request to the specific handler function
    # Functions should now set the RESPONSE variable with the FULL HTTP response
    case "$ROUTING_REQUEST" in
        "GET /contagem-pessoas") handle_GET_count ;;
        "GET /pessoas")          handle_GET_search ;;
        "GET /pessoas/:id")      handle_GET_find ;;
        "POST /pessoas")         handle_POST_create ;;
        *)                       handle_not_found ;;
    esac

    # Output the full HTTP response to stdout
    # The handler functions are now responsible for generating the status line, headers, and body.
    # Example expected format in $RESPONSE:
    # HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 123\r\n\r\n{"key":"value"}
    echo -ne "$RESPONSE"
}

# --- Adapt handler functions to output full HTTP response --- 
# Example adaptation for not-found (others need similar changes)
function handle_not_found() {
    RESPONSE="HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: 9\r\n\r\nNot Found"
}

# --- Adapt create.bash --- 
# It already returns 201 with Location header, needs slight format adjustment
# Ensure it sets RESPONSE like: "HTTP/1.1 201 Created\r\nLocation: /pessoas/$UUID\r\nContent-Length: 0\r\n\r\n"

# --- Adapt search.bash, find.bash, count.bash --- 
# Ensure they set RESPONSE with status, Content-Type, Content-Length, and JSON/text body.
# Example for count:
# function handle_GET_count() {
#     COUNT=$(psql ...)
#     BODY="$COUNT"
#     CONTENT_LENGTH=${#BODY}
#     RESPONSE="HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: $CONTENT_LENGTH\r\n\r\n$BODY"
# }

# --- Main execution --- 
handleRequest_bhg

