import unittest
import air

class AirQualityTest(unittest.TestCase):
    def test_environment_variables(self):
        import os
        d = os.environ['AIRQUALITY_DATA'] 
        self.assertIsNotNone(d)
        c = os.environ['REDIS_URL']
        self.assertIsNotNone(c)

    def test_getting_data(self):
        a = air.AirQuality(37.794678, -122.41143).getData()
        self.assertIsNotNone(a)
        self.assertIsNotNone(a["category"])
        self.assertIsNotNone(a["caution"])
        self.assertIsNotNone(a["score"])
    
    def test_score(self):
        a = air.AirQuality(37.794678, -122.41143)
        self.assertEqual(a.AQIPM25(120),184.0)

    def test_category(self):
        a = air.AirQuality(37.794678, -122.41143)
        d = a.AQICategory(120)
        self.assertIsNotNone(d)
        self.assertIsNotNone(d["category"])
        self.assertEqual(d["category"], "Unhealthy for Sensitive Groups")
        
if __name__ == '__main__':
    unittest.main()