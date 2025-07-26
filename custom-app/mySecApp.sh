#!/bin/bash

echo "🚀 Creating test containers with different labels..."

# Nettoyer les anciens conteneurs de test
docker ps -a --filter "label=test_container=true" -q | xargs docker rm -f 2>/dev/null || true

# 1. Conteneur AVEC métriques custom (votre app)
echo "📊 Creating container WITH custom metrics..."
docker run -d \
    --label monitored=true \
    --label test_container=true \
    --label "image=custom-metrics-app" \
    --label "app_type=backend" \
    --label "environment=production" \
    --label "prometheus_port=8080" \
    --label "metrics_path=/metrics" \
    --network desktop_monitoring \
    -p 8083:8080 \
    --name "custom-app-with-metrics" \
    custom-metrics-app:latest

# 2. Conteneur SANS métriques custom - Nginx
echo "🌐 Creating Nginx container WITHOUT custom metrics..."
docker run -d \
    --label monitored=true \
    --label test_container=true \
    --label "image=nginx" \
    --label "app_type=frontend" \
    --label "environment=production" \
    --label "prometheus_port=80" \
    --label "metrics_path=/metrics" \ 
    --network desktop_monitoring \
    -p 8081:80 \
    --name "nginx-no-metrics" \
    nginx:alpine

# 3.conteneur SANS monitoring - Redis
echo "💾 Creating Redis container WITHOUT monitoring..."
docker run -d \
    --label test_container=true \
    --label "image=redis" \
    --label "app_type=database" \
    --label "environment=development" \
    --network desktop_monitoring \
    --label "prometheus_port=6379" \
    --label "metrics_path=/metrics" \
    -p 6379:6379 \
    --name "redis-unmonitored" \
    redis:alpine

# 4. Conteneur avec métriques custom - App Python
echo "🐍 Creating Python app container WITH custom metrics..."
docker run -d \
    --label monitored=true \
    --label test_container=true \
    --label "image=python-metrics-app" \
    --label "app_type=api" \
    --label "environment=staging" \
    --label "prometheus_port=8000" \
    --label "metrics_path=/metrics" \
    --network desktop_monitoring \
    -p 8082:8000 \
    --name "python-app-with-metrics" \
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
echo ""
echo "✅ Test containers created!"
echo ""
echo "🔍 Testing endpoints:"
echo "• Custom App: http://localhost:8083/metrics"
echo "• Python App: http://localhost:8082/metrics"
echo "• Nginx: http://localhost:8081/ (no metrics endpoint)"
echo ""
echo "📊 In Grafana, you'll see:"
echo "• cAdvisor metrics for ALL containers (CPU, RAM, etc.)"
echo "• Custom metrics only for containers with prometheus_port label"
