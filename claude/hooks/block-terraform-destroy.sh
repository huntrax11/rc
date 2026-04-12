#!/bin/bash
# Extract the command from the JSON input provided by Claude Code (stdin)
COMMAND=$(jq -r '.tool_input.command')

# Check if the command contains 'terraform destroy'
if echo "$COMMAND" | grep -q 'terraform destroy'; then
  # Return a deny decision and the reason in JSON format
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "🚨 [System Block] The terraform destroy command is strictly prohibited by a system hook."
    }
  }'
else
  # Allow safe commands to execute normally
  exit 0
fi
