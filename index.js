const express = require('express');
const quotes = require('./quotes.json');
const client = require('prom-client'); // Import the prom-client library

const app = express();
const PORT = process.env.PORT || 8080;

// --- START: Prometheus Metrics Configuration ---

// 1. Create a Registry to register all your metrics
const register = new client.Registry();

// 2. Add a default label to all metrics
register.setDefaultLabels({
  app: 'quote-api'
});

// 3. Enable the collection of default metrics (CPU, memory, etc.)
client.collectDefaultMetrics({ register });

// 4. Create a custom metric - a counter for total HTTP requests
const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests made.',
  labelNames: ['method', 'route', 'code'],
  registers: [register]
});

// 5. Create a middleware to count all incoming requests
app.use((req, res, next) => {
  res.on('finish', () => {
    // Increment the counter after the response is finished
    httpRequestCounter.inc({
      method: req.method,
      route: req.path,
      code: res.statusCode
    });
  });
  next();
});

// --- END: Prometheus Metrics Configuration ---


/* ---------- routes ---------- */

// A route for Prometheus to scrape the metrics
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (ex) {
    res.status(500).end(ex);
  }
});


// simple welcome
app.get('/', (_, res) => {
  res.send('Welcome to the Quote API v2.1 (Metrics Enabled) 😎');
});

/* crash‑after‑5‑seconds demo  */
app.get('/quote', (_, res) => {
  res.json({ quote: 'This is a quote endpoint.' });
});

/* list all quotes */
app.get('/quotes', (_, res) => res.json(quotes));

/* ---------- start server ---------- */
app.listen(PORT, () => console.log(`listening on ${PORT}`));
