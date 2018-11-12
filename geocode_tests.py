import unittest
from geocode import GeoCode

class GeoCodeTest(unittest.TestCase):
    def test_checkCenter(self):
        val = GeoCode("San Francisco, CA").getLatLng()    
        self.assertEqual(val, {'lat': 37.794678, 'lng': -122.41143})
    
if __name__ == '__main__':
    unittest.main()