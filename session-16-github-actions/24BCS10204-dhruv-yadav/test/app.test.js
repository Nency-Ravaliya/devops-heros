'use strict';

const request = require('supertest');
const { createApp, DEFAULT_GREETING } = require('../src/app');
const calculator = require('../src/calculator');

describe('calculator', () => {
  test('add', () => expect(calculator.add(10, 5)).toBe(15));
  test('subtract', () => expect(calculator.subtract(10, 5)).toBe(5));
  test('multiply', () => expect(calculator.multiply(10, 5)).toBe(50));
  test('divide', () => expect(calculator.divide(10, 5)).toBe(2));
  test('divide by zero throws', () => {
    expect(() => calculator.divide(10, 0)).toThrow('Cannot divide by zero');
  });
});

describe('HTTP API', () => {
  test('GET /health returns ok', async () => {
    const res = await request(createApp({})).get('/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: 'ok' });
  });

  test('GET / uses default greeting when no secret is set', async () => {
    const res = await request(createApp({})).get('/');
    expect(res.status).toBe(200);
    expect(res.body.message).toBe(DEFAULT_GREETING);
    expect(res.body.greetingSource).toBe('default');
  });

  test('GET / uses APP_GREETING when the secret is set', async () => {
    const res = await request(createApp({ APP_GREETING: 'test-greeting' })).get('/');
    expect(res.body.message).toBe('test-greeting');
    expect(res.body.greetingSource).toBe('secret');
  });

  test('GET /api/add computes a sum', async () => {
    const res = await request(createApp({})).get('/api/add?a=2&b=3');
    expect(res.status).toBe(200);
    expect(res.body.result).toBe(5);
  });

  test('GET /api/divide by zero returns 400', async () => {
    const res = await request(createApp({})).get('/api/divide?a=1&b=0');
    expect(res.status).toBe(400);
  });

  test('non-numeric input returns 400', async () => {
    const res = await request(createApp({})).get('/api/add?a=x&b=1');
    expect(res.status).toBe(400);
  });

  test('unknown operation returns 404', async () => {
    const res = await request(createApp({})).get('/api/pow?a=1&b=1');
    expect(res.status).toBe(404);
  });
});
