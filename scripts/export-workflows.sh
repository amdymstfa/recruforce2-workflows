#!/bin/bash

# ===================================================
# Export N8N Workflows
# ===================================================

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"
BACKUP_FILE="$BACKUP_DIR/workflows-$TIMESTAMP.json"

mkdir -p "$BACKUP_DIR"

echo "🔄 Exporting N8N workflows..."

# Export via N8N CLI
docker exec recruforce2-n8n n8n export:workflow --all --output=/tmp/workflows.json

# Copy from container
docker cp recruforce2-n8n:/tmp/workflows.json "$BACKUP_FILE"

echo "✅ Workflows exported to: $BACKUP_FILE"
