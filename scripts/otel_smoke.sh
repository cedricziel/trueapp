#!/usr/bin/env bash
# Sends one OTLP/JSON log record and one span to an OTLP/HTTP endpoint using
# the exact wire format flutter_otel's OtlpHttpLogExporter / OtlpHttpSpanExporter
# produce (JSON protobuf mapping, hex trace/span ids, nanos as strings, intValue
# as string). Lets you validate an ingest endpoint + headers with nothing but
# curl, independent of building the app.
#
# Usage (same env vars the app reads via --dart-define):
#   OTEL_EXPORTER_OTLP_ENDPOINT=https://ingest.example/otlp \
#   OTEL_EXPORTER_OTLP_HEADERS="authorization=Bearer KEY,x-tenant-id=homelab,x-dataset-id=apps" \
#   OTEL_SERVICE_NAME=truehub OTEL_DEPLOYMENT_ENVIRONMENT=smoke \
#   scripts/otel_smoke.sh
#
# Exit code is non-zero if either signal gets a non-2xx response. The run id
# printed at the end is stamped on both the log record and the span as
# `smoke.run_id`, so you can search for it in the backend.
set -euo pipefail

endpoint="${OTEL_EXPORTER_OTLP_ENDPOINT:?set OTEL_EXPORTER_OTLP_ENDPOINT}"
raw_headers="${OTEL_EXPORTER_OTLP_HEADERS:-}"
service_name="${OTEL_SERVICE_NAME:-truehub}"
environment="${OTEL_DEPLOYMENT_ENVIRONMENT:-smoke}"

# Mirror TelemetryConfig.parseHeaders: split on ',', then on the first '='.
header_args=()
IFS=',' read -r -a pairs <<<"$raw_headers"
for pair in "${pairs[@]}"; do
  pair="$(echo "$pair" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  [[ -z "$pair" || "$pair" != *=* ]] && continue
  key="${pair%%=*}"; value="${pair#*=}"
  [[ -z "$key" ]] && continue
  header_args+=(-H "$key: $value")
done

# Mirror resolveLogsEndpoint/resolveTracesEndpoint: strip one trailing '/'.
base="${endpoint%/}"
logs_url="$base/v1/logs"
traces_url="$base/v1/traces"

rand_hex() { head -c "$1" /dev/urandom | xxd -p | tr -d '\n'; }
trace_id="$(rand_hex 16)"
span_id="$(rand_hex 8)"
run_id="$(rand_hex 6)"
now_ns="$(python3 -c 'import time; print(time.time_ns())')"
start_ns=$((now_ns - 250000000))

resource_attrs=$(cat <<JSON
[{"key":"service.name","value":{"stringValue":"$service_name"}},
 {"key":"deployment.environment","value":{"stringValue":"$environment"}}]
JSON
)

log_body=$(cat <<JSON
{"resourceLogs":[{"resource":{"attributes":$resource_attrs},
 "scopeLogs":[{"scope":{"name":"truehub"},
 "logRecords":[{"timeUnixNano":"$now_ns","observedTimeUnixNano":"$now_ns",
  "severityNumber":17,"severityText":"ERROR",
  "body":{"stringValue":"otel smoke test log (run $run_id)"},
  "attributes":[{"key":"smoke.run_id","value":{"stringValue":"$run_id"}},
                {"key":"exception.type","value":{"stringValue":"SmokeTestException"}},
                {"key":"attempt","value":{"intValue":"1"}},
                {"key":"server.network.trusted","value":{"boolValue":true}}],
  "traceId":"$trace_id","spanId":"$span_id"}]}]}]}
JSON
)

trace_body=$(cat <<JSON
{"resourceSpans":[{"resource":{"attributes":$resource_attrs},
 "scopeSpans":[{"scope":{"name":"truehub"},
 "spans":[{"traceId":"$trace_id","spanId":"$span_id","name":"truenas.connect",
  "kind":3,"startTimeUnixNano":"$start_ns","endTimeUnixNano":"$now_ns",
  "attributes":[{"key":"smoke.run_id","value":{"stringValue":"$run_id"}},
                {"key":"server.id","value":{"stringValue":"smoke-server"}}],
  "events":[{"timeUnixNano":"$now_ns","name":"exception",
    "attributes":[{"key":"exception.message","value":{"stringValue":"smoke"}}]}],
  "status":{"code":2,"message":"smoke failure"}}]}]}]}
JSON
)

post() {
  local label="$1" url="$2" body="$3"
  local tmp; tmp="$(mktemp)"
  local status
  status="$(curl -sS -o "$tmp" -w '%{http_code}' -X POST "$url" \
    -H 'Content-Type: application/json' "${header_args[@]}" --data "$body" || echo "000")"
  printf '%-7s %s -> HTTP %s\n' "$label" "$url" "$status"
  if [[ -s "$tmp" ]]; then printf '        body: %s\n' "$(head -c 500 "$tmp")"; fi
  rm -f "$tmp"
  [[ "$status" =~ ^2 ]]
}

ok=0
post logs   "$logs_url"   "$log_body"   || ok=1
post traces "$traces_url" "$trace_body" || ok=1
echo "run_id=$run_id trace_id=$trace_id"
exit $ok
