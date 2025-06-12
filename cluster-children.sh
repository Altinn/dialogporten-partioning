#!/bin/bash
# ====================================================================
# SCRIPT TO CLUSTER DIALOG CHILD TABLES USING PG_REPACK
# ====================================================================
# This script physically reorders child tables based on their parent's
# foreign key to improve JOIN performance.
# It should be run periodically (e.g., weekly) via cron.
#
# REQUIREMENTS:
# - pg_repack must be installed and in the system's PATH.
# - The user running the script must have appropriate permissions.
# ====================================================================

set -euo pipefail # Fail on error, unbound variable, or pipe failure

# --- DATABASE CONNECTION DETAILS (EDIT THESE) ---
DB_HOST="localhost"
DB_PORT="5432"
DB_USER="your_user"
DB_NAME="your_database"

# Set the PGPASSWORD environment variable to avoid password prompts
# It's recommended to use a .pgpass file for production environments.
export PGPASSWORD="your_password"

# --- TABLE AND CLUSTER KEY CONFIGURATION ---
# Associative array mapping "TableName" to its "ClusteringKey"
# Add or remove tables as needed.
declare -A TABLES_TO_CLUSTER=(
    # Direct Children of Dialog
    ["DialogTransmission"]="DialogId"
    ["DialogActivity"]="DialogId"
    ["DialogContent"]="DialogId"
    ["Attachment"]="DialogId"
    ["DialogGuiAction"]="DialogId"
    ["DialogApiAction"]="DialogId"
    ["DialogEndUserContext"]="DialogId"
    ["DialogServiceOwnerContext"]="DialogId"
    ["DialogSeenLog"]="DialogId"
    ["DialogSearchTag"]="DialogId"

    # Grandchildren (and deeper in the hierarchy)
    ["Actor"]="ActivityId" # Actor's most direct link to the hierarchy.
    ["DialogTransmissionContent"]="TransmissionId"
    ["AttachmentUrl"]="AttachmentId"
    ["DialogApiActionEndpoint"]="ActionId"
    ["DialogServiceOwnerLabel"]="DialogServiceOwnerContextId"
    ["LabelAssignmentLog"]="ContextId"

    # Polymorphic/Complex Children
    ["LocalizationSet"]="DialogContentId" # Clustering by the most likely path
)

# --- EXECUTION LOGIC ---
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log "Starting child table clustering process for database '$DB_NAME'."

for table in "${!TABLES_TO_CLUSTER[@]}"; do
    cluster_key="${TABLES_TO_CLUSTER[$table]}"
    log "Attempting to repack and cluster table '$table' on key '$cluster_key'..."

    # Construct the pg_repack command
    # The --no-order-by is a legacy alias, --order-by is correct.
    # We use double quotes to handle case-sensitive names.
    PGREPACK_CMD="pg_repack --host=$DB_HOST --port=$DB_PORT --username=$DB_USER --dbname=$DB_NAME --table=\"public.$table\" --order-by=\"$cluster_key\" --wait-timeout=300"

    # Execute the command
    if eval "$PGREPACK_CMD"; then
        log "SUCCESS: Successfully repacked table '$table'."
    else
        log "ERROR: Failed to repack table '$table'. Check logs for details."
        # Decide if you want the script to exit on first failure or continue.
        # To continue, remove 'exit 1'.
        exit 1
    fi
done

log "Clustering process completed successfully."
exit 0
