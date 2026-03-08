#!/bin/bash
# Mock Claude CLI that outputs stream-json events
echo '{"type":"system","subtype":"init","session_id":"test-session-1","message":"starting"}'
echo '{"type":"assistant","message":{"content":[{"text":"I will fix the bug."}]},"usage":{"input_tokens":50,"output_tokens":20}}'
echo '{"type":"result","result":"Task completed","session_id":"test-session-1","usage":{"input_tokens":100,"output_tokens":40}}'
exit 0
