#!/bin/bash

#  Conteneur avec métriques custom - App Python
echo " Creating Python app container WITH custom metrics..."
docker run -d \
    --label monitored=true \
    --label "image=python-metrics-app" \
    --label "prometheus_port=8000" \
    --label "metrics_path=/metrics" \
    --network desktop_monitoring \
    -p 8082:8000 \
    --name "python-app-with-metrics-$(date +%s)" \
    --entrypoint="" \
    python:3.9-slim \
    bash -c "pip install prometheus_client flask && python -c \"
from flask import Flask
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
import time

app = Flask(__name__)
request_count = Counter('python_app_requests_total', 'Total requests', ['method', 'endpoint'])

@app.route('/')
def home():
    request_count.labels(method='GET', endpoint='/').inc()
    return 'Python App with Metrics!'

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
\""


echo " Creating containers that expose Prometheus metrics..."

docker run -d --label monitored=true --label "image=nginx-exporter" --label "prometheus_port=9113" --label "metrics_path=/metrics"  --network desktop_monitoring --name "nginx-exporter-$(date +%s)" nginx/nginx-prometheus-exporter:latest

docker run -d --label monitored=true --label "image=redis-exporter" --label "prometheus_port=9121" --label "metrics_path=/metrics" --network desktop_monitoring --name "redis-exporter-$(date +%s)" oliver006/redis_exporter:latest

echo "containers with REAL prometheus metrics created!"
echo ""
echo " These containers expose /metrics endpoints:"
echo " Redis Exporter: Redis metrics"
echo " Nginx Exporter: Nginx metrics"
echo ""
echo "Current monitored containers:"
docker ps --filter "label=monitored=true" --format "→ {{.Names}} ({{.Image}}) - {{.Status}}"

echo "🔍 Testing endpoints:"
echo "• Custom App: http://localhost:8080/metrics"
echo "• Python App: http://localhost:8082/metrics"
