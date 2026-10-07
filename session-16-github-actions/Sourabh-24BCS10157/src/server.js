'use strict';

const { createApp } = require('./app');

const port = Number(process.env.PORT) || 3000;

createApp().listen(port, () => {
  console.log(`s16-cicd-demo listening on port ${port}`);
});
