import unittest
from app.app import app

class TestDevSecOpsApp(unittest.TestCase):
    def setUp(self):
        app.config['TESTING'] = True
        self.client = app.test_client()

    def test_home(self):
        rv = self.client.get('/')
        self.assertEqual(rv.status_code, 200)
        self.assertIn(b"DevSecOps Demo Application", rv.data)

    def test_health(self):
        rv = self.client.get('/health')
        self.assertEqual(rv.status_code, 200)
        self.assertIn(b"healthy", rv.data)

    def test_status(self):
        rv = self.client.get('/api/status')
        self.assertEqual(rv.status_code, 200)
        self.assertIn(b"running", rv.data)

if __name__ == '__main__':
    unittest.main()

