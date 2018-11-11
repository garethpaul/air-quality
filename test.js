const request = require('request');

function AQIPM25(Concentration)
{
    var Conc=parseFloat(Concentration);
    var c;
    var AQI;
    c=(Math.floor(10*Conc))/10;
    if (c>=0 && c<12.1)
    {
        AQI=Linear(50,0,12,0,c);
    }
    else if (c>=12.1 && c<35.5)
    {
        AQI=Linear(100,51,35.4,12.1,c);
    }
    else if (c>=35.5 && c<55.5)
    {
        AQI=Linear(150,101,55.4,35.5,c);
    }
    else if (c>=55.5 && c<150.5)
    {
        AQI=Linear(200,151,150.4,55.5,c);
    }
    else if (c>=150.5 && c<250.5)
    {
        AQI=Linear(300,201,250.4,150.5,c);
    }
    else if (c>=250.5 && c<350.5)
    {
        AQI=Linear(400,301,350.4,250.5,c);
    }
    else if (c>=350.5 && c<500.5)
    {
        AQI=Linear(500,401,500.4,350.5,c);
    }
    else
    {
        AQI="PM25message";
    }
    return AQI;
}


request('https://api.thingspeak.com/channels/370620/fields/8.json?start=2018-11-11%2013:23:38&offset=0&round=0&average=10&results=12000&api_key=KD5U9IJ2Y377TKXZ', { json: true }, (err, res, body) => {
  if (err) { return console.log(err); }
  var feeds = body['feeds'];
  var last = Object.keys(feeds).length-1
  var a = AQIPM25(feeds[last]["field8"])
  console.log(a)
});