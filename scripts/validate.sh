# Créer scripts/validate.sh
#!/bin/bash
set -e

echo "🔍 Validating deployment..."

# Test des services
services=(
    "prometheus:9090"
    "grafana:3000"
    "node-exporter:9100"
    "cadvisor:8080"
    "alertmanager:9093"
)

for service in "${services[@]}"; do
    name="${service%:*}"
    port="${service#*:}"
    echo "Testing $name on port $port..."
    
    if curl -f -s "http://localhost:$port" > /dev/null; then
        echo "✅ $name is responding"
    else
        echo "❌ $name is not responding"
    fi
done

echo "✅ Validation completed!"