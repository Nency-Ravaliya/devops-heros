import json
import threading
import unittest
import urllib.error
import urllib.request
from http.server import HTTPServer
from app import Handler


class AppTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = HTTPServer(("127.0.0.1", 0), Handler)
        cls.worker = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.worker.start()
        cls.base = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.worker.join(timeout=5)

    def test_home_message(self):
        with urllib.request.urlopen(self.base, timeout=5) as response:
            self.assertEqual(response.status, 200)
            self.assertEqual(json.load(response)["message"], "Hello from my DevOps pipeline")

    def test_health_endpoint(self):
        with urllib.request.urlopen(self.base + "/health", timeout=5) as response:
            self.assertTrue(json.load(response)["healthy"])

    def test_json_content_type(self):
        with urllib.request.urlopen(self.base + "/health", timeout=5) as response:
            self.assertEqual(response.headers.get_content_type(), "application/json")

    def test_content_length(self):
        with urllib.request.urlopen(self.base, timeout=5) as response:
            self.assertEqual(len(response.read()), int(response.headers["Content-Length"]))

    def test_missing_route(self):
        with self.assertRaises(urllib.error.HTTPError) as error:
            urllib.request.urlopen(self.base + "/missing", timeout=5)
        self.assertEqual(error.exception.code, 404)


if __name__ == "__main__":
    unittest.main()
