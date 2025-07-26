const express = require('express');
const client = require('prom-client');

const app = express();

client.collectDefaultMetrics();

const httpRequestsTotal = new client.Counter({
    name: 'my_app_requests_total',
    help: 'Nombre total de requetes HTTP',
    labelNames: ['method', 'route', 'status_code']
});

app.use((req, res, next) => {
    res.on('finish', () => {
        httpRequestsTotal.inc({
            method: req.method,
            route: req.path,
            status_code: res.statusCode.toString()
        });
    });
    next();
});

app.get('/', (req, res) => {
    res.send('Hello from Custom Metrics App!');
});

app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
    });
});

app.get('/metrics', async (req, res) => {
    res.set('Content-Type', client.register.contentType);
    res.end(await client.register.metrics());
});

const PORT = process.env.PORT || 8080;

app.listen(PORT, '0.0.0.0', () => {
    console.log('Custom metrics app listening on port ' + PORT);
    console.log('Metrics available at http://localhost:' + PORT + '/metrics');
    console.log('Health check at http://localhost:' + PORT + '/health');
});
