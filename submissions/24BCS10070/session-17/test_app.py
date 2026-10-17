import unittest
from app import message

class AppTests(unittest.TestCase):
    def test_health(self):
        self.assertTrue(message()["healthy"])
    def test_message(self):
        self.assertIn("DevOps", message()["message"])

if __name__ == "__main__":
    unittest.main()
