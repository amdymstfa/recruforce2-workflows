#!/bin/bash

# ===================================================
# Import N8N Workflows
# ===================================================

WORKFLOWS_DIR="./workflows"

echo "🔄 Importing N8N workflows..."

# Import each workflow
for file in "$WORKFLOWS_DIR"/*.json; do
    filename=$(basename "$file")
    echo "Importing $filename..."

    docker cp "$file" recruforce2-n8n:/tmp/workflow.json
    docker exec recruforce2-n8n n8n import:workflow --input=/tmp/workflow.json
done

echo "✅ All workflows imported"
