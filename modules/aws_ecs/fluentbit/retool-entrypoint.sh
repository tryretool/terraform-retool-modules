#!/bin/bash

set -euf -o pipefail

config=$(cat <<EOF
[OUTPUT]
    Name    forward
    Match   retool-firelens*
    Host    telemetry.${SERVICE_DISCOVERY_NAMESPACE}
    Port    9000
EOF
)

echo "$config" > /extra.conf
exec /entrypoint.sh
