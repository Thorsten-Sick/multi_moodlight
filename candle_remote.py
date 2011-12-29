#!/usr/bin/python
""" Remote control for Arduino TLC

Canle, rmin,rmax, gmin, gmax, bluemin, bluemx, brightnessmin/max
1,90,90,30,30,10,10,90,100g

"""

import serial
import time
import random
#ser = serial.Serial("/dev/ttyACM0", baudrate = 9600)

class Candle():
    """ A candle
    """

    def __init__(self, ser, number = 1, autoupdate = True):
        """ Inits a candle and sets it to default values

        ser: Serial interface
        number: Number of the candle
        autoupdate: automatically update the real candle
        """

        self.rmin=0 # Red
        self.rmax=0
        self.gmin=0 # Green
        self.gmax=0
        self.bmin=0 # Blue
        self.bmax=0
        self.hmin=0 # Helligkeit (brightness, b already used)
        self.hmax=0

        self.autoupdate = autoupdate
        self.number = number
        self.ser = ser

    def update(self):
        """ Send data to candle
        """

        command = "" + str(self.number)+"," + str(self.rmin) + "," + str(self.rmax) + ","\
             + str(self.gmin) + "," + str(self.gmax) + ","\
             + str(self.bmin) + "," + str(self.bmax) + ","\
             + str(self.hmin) + "," + str(self.hmax) + "g"

        print command + "\n"
        print self.ser.write(command)

    def set(self, rmin=None, rmax=None, gmin=None, gmax=None,bmin=None, bmax=None,hmin=None, hmax=None):
        """ Set the values for a candle

        rmin, rmax: Min/max red
        gmin, gmax: Min/max green
        bmin, bmax: Min/max blue
        hmin, hmax: Min/max helligkeit (brightness)
        """

        if rmin:
            self.rmin = rmin
        if rmax:
            self.rmax = rmax
        if gmin:
            self.gmin = gmin
        if gmax:
            self.gmax = gmax
        if bmin:
            self.bmin = bmin
        if bmax:
            self.bmax = bmax
        if hmin:
            self.hmin = hmin
        if hmax:
            self.hmax = hmax

        if self.autoupdate:
            self.update()

    def simpleset(self,r,g,b,h):
        """ Just set rgbh
        """

        self.set(r,r,g,g,b,b,h,h)

def candles_random(cs):
    """ Set candles randomly
    """
    while 1:
        for i in cs:
            i.simpleset(random.randint(0,100),random.randint(0,100),random.randint(0,100),random.randint(0,100))
            i.update()
            time.sleep(1)

def candles_fire(cs):
    """ Simulate fire
    """

    print len(cs)
    while 1:
        for i in cs:
            i.simpleset(random.randint(80,100),random.randint(80,100),random.randint(20,25),random.randint(90,100))
            time.sleep(1)

if __name__=="__main__":
    ser = serial.Serial("/dev/ttyACM0", baudrate = 9600)
    #print ser.write("1,90,90,20,20,30,30,20,100g")
    cs = []
    for i in range(5):
        c1 = Candle(ser, number = i)
        c1.update()
        cs.append(c1)

#    candles_random(cs)
    candles_random(cs)
