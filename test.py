import requests
import json
import math
from math import cos, asin, sqrt

#r = requests.get('https://api.thingspeak.com/channels/370620/fields/8.json?start=2018-11-11%2013:23:38&offset=0&round=0&average=10&results=12000&api_key=KD5U9IJ2Y377TKXZ')
#results = r.json()['feeds']
#latest = results[-1]


class airquality(object):
    """AirQuality Class

    Attributes:
        lat: latitude of user
        lng: longitude of user
    """

    def __init__(self, lat, lng):
        """Return a new Truck object."""
        self.lat = lat
        self.lng = lng

    def getData(self):
        r = requests.get('https://www.purpleair.com/json')
        results = r.json()['results']
        index = 0
        d_ = 1000000
        for item in results:
            i = item
            if i['Lat']:
                d = self.distance(self.lat,self.lng, i['Lat'], i['Lon'])
                if d < d_:
                    d_ = d
                    index = results.index(i)
        pm25 = results[index]['PM2_5Value']
        a = self.AQIPM25(pm25)
        return (self.AQICategory(a))

    def distance(self, lat1, lon1, lat2, lon2):
        p = 0.017453292519943295     #Pi/180
        a = 0.5 - cos((lat2 - lat1) * p)/2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2
        return 12742 * asin(sqrt(a)) #2*R*asin...

    def AQIPM25(self, raw_value):
        conc = float(raw_value)
        c = (math.floor(10*conc))/10
        AQI = 0
        if (c>=0 and c<12.1):
            AQI = self.Linear(50,0,12,0,c)
        elif (c>=12.1 and c<35.5):
            AQI = self.Linear(100,51,35.4,12.1,c)
        elif (c>=35.5 and c<55.5):
            AQI = self.Linear(150,101,55.4,35.5,c)
        elif (c>=55.5 and c<150.5):
            AQI = self.Linear(200,151,150.4,55.5,c)
        elif (c>=150.5 and c<250.5):
            AQI = self.Linear(300,201,250.4,150.5,c)
        elif (c>=250.5 and c<350.5):
            AQI = self.Linear(400,301,350.4,250.5,c);
        elif (c>=350.5 and c<500.5):
            AQI = self.Linear(500,401,500.4,350.5,c)
        else:
            AQI="PM25message"
        return AQI

    @staticmethod
    def Linear(AQIhigh, AQIlow, Conchigh, Conclow, Concentration):
        linear = 0
        Conc = float(Concentration)
        a = ((Conc-Conclow)/(Conchigh-Conclow))*(AQIhigh-AQIlow)+AQIlow
        linear = round(a)
        return linear

    @staticmethod
    def AQICategory(AQIndex):
        AQI=float(AQIndex)
        if (AQI<=50):
            AQICategory="Good"
            C = "None"
        elif (AQI>50 and AQI<=100):
            AQICategory="Moderate"
            C = "Unusually sensitive people should consider reducing prolonged or heavy exertion."
        elif (AQI>100 and AQI<=150):
            AQICategory="Unhealthy for Sensitive Groups"
            C = "People with respiratory or heart disease, the elderly and children should limit prolonged exertion."
        elif (AQI>150 and AQI<=200):
            AQICategory="Unhealthy"
            C = "People with respiratory or heart disease, the elderly and children should avoid prolonged exertion; everyone else should limit prolonged exertion."
        elif (AQI>200 and AQI<=300):
            AQICategory="Very Unhealthy"
            C = "People with respiratory or heart disease, the elderly and children should avoid any outdoor activity; everyone else should avoid prolonged exertion."
        elif (AQI>300 and AQI<=400):
            AQICategory="Hazardous"
            C = "Everyone should avoid any outdoor exertion; people with respiratory or heart disease, the elderly and children should remain indoors."
        elif (AQI>400 and AQI<=500):
            AQICategory="Hazardous"
            C = "Everyone should avoid any outdoor exertion; people with respiratory or heart disease, the elderly and children should remain indoors."
        else:
            AQICategory="Out of Range"
        return {"category": AQICategory, "caution": C, "score": int(AQI)}

if __name__ == "__main__":
    a = airquality(38.07696, -122.547431)
    print(a.getData())
