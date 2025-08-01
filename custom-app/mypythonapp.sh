echo "🐍 Creating Python app container WITH custom metrics..."

# Créer un script Python temporaire
cat > /tmp/python_metrics_app.py << 'EOF'
from flask import Flask
from prometheus_client import Counter, generate_latest, CONTENT_TYPE_LATEST
import time
import threading

app = Flask(__name__)
request_count = Counter('python_app_requests_total', 'Total requests', ['method', 'endpoint'])

@app.route('/')
def home():
    request_count.labels(method='GET', endpoint='/').inc()
    return 'Python App with Metrics!'

@app.route('/health')
def health():
    return 'OK'

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

if __name__ == '__main__':
    print("Starting Python metrics app on port 8000...")
    app.run(host='0.0.0.0', port=8000, debug=False)
EOF

# Lancer le conteneur avec le script monté
docker run -d \
    --label monitored=true \
    --label "image=python-metrics-app" \
    --label "prometheus_port=8000" \
    --label "metrics_path=/metrics" \
    --network docker-monitoring_monitoring \
    -p 8083:8000 \
    -v /tmp/python_metrics_app.py:/app/app.py \
    --name "python-app-with-metrics-$(date +%s)" \
    python:3.9-slim \
    bash -c "cd /app && pip install prometheus_client flask && python app.py"
