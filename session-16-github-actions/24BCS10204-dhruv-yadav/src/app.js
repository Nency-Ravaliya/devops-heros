'use strict';

const express = require('express');
const calculator = require('./calculator');

const DEFAULT_GREETING = 'Hello from the Session 16 CI/CD pipeline';

function createApp(env = process.env) {
  const app = express();
  app.disable('x-powered-by');

  // APP_GREETING is injected from a GitHub Actions secret -> Kubernetes Secret.
  // We only ever report *whether* it was configured, never echo it in logs.
  const greeting = env.APP_GREETING || DEFAULT_GREETING;
  const greetingSource = env.APP_GREETING ? 'secret' : 'default';

  app.get('/', (req, res) => {
    res.json({
      app: 's16-cicd-demo',
      student: 'Dhruv Yadav (24BCS10204)',
      message: greeting,
      greetingSource,
      version: env.APP_VERSION || 'dev',
    });
  });

  app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  app.get('/api/:op', (req, res) => {
    const { op } = req.params;
    const a = Number(req.query.a);
    const b = Number(req.query.b);

    if (!Object.hasOwn(calculator, op)) {
      return res.status(404).json({ error: `Unknown operation '${op}'` });
    }
    if (Number.isNaN(a) || Number.isNaN(b)) {
      return res.status(400).json({ error: 'Query params a and b must be numbers' });
    }

    try {
      return res.json({ op, a, b, result: calculator[op](a, b) });
    } catch (err) {
      return res.status(400).json({ error: err.message });
    }
  });

  return app;
}

module.exports = { createApp, DEFAULT_GREETING };
