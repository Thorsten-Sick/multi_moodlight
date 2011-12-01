/*
    Basic Pin setup:
    ------------                                  ---u----
    ARDUINO   13|-> SCLK (pin 25)           OUT1 |1     28| OUT channel 0
              12|                           OUT2 |2     27|-> GND (VPRG)
              11|-> SIN (pin 26)            OUT3 |3     26|-> SIN (pin 11)
              10|-> BLANK (pin 23)          OUT4 |4     25|-> SCLK (pin 13)
               9|-> XLAT (pin 24)             .  |5     24|-> XLAT (pin 9)
               8|                             .  |6     23|-> BLANK (pin 10)
               7|                             .  |7     22|-> GND
               6|                             .  |8     21|-> VCC (+5V)
               5|                             .  |9     20|-> 2K Resistor -> GND
               4|                             .  |10    19|-> +5V (DCPRG)
               3|-> GSCLK (pin 18)            .  |11    18|-> GSCLK (pin 3)
               2|                             .  |12    17|-> SOUT
               1|                             .  |13    16|-> XERR
               0|                           OUT14|14    15| OUT channel 15
    ------------                                  --------

    -  Put the longer leg (anode) of the LEDs in the +5V and the shorter leg
         (cathode) in OUT(0-15).
    -  +5V from Arduino -> TLC pin 21 and 19     (VCC and DCPRG)
    -  GND from Arduino -> TLC pin 22 and 27     (GND and VPRG)
    -  digital 3        -> TLC pin 18            (GSCLK)
    -  digital 9        -> TLC pin 24            (XLAT)
    -  digital 10       -> TLC pin 23            (BLANK)
    -  digital 11       -> TLC pin 26            (SIN)
    -  digital 13       -> TLC pin 25            (SCLK)
    -  The 2K resistor between TLC pin 20 and GND will let ~20mA through each
       LED.  To be precise, it's I = 39.06 / R (in ohms).  This doesn't depend
       on the LED driving voltage.
    - (Optional): put a pull-up resistor (~10k) between +5V and BLANK so that
                  all the LEDs will turn off when the Arduino is reset.

    If you are daisy-chaining more than one TLC, connect the SOUT of the first
    TLC to the SIN of the next.  All the other pins should just be connected
    together:
        BLANK on Arduino -> BLANK of TLC1 -> BLANK of TLC2 -> ...
        XLAT on Arduino  -> XLAT of TLC1  -> XLAT of TLC2  -> ...
    The one exception is that each TLC needs it's own resistor between pin 20
    and GND.

    This library uses the PWM output ability of digital pins 3, 9, 10, and 11.
    Do not use analogWrite(...) on these pins.

    This sketch does the Knight Rider strobe across a line of LEDs.

    Alex Leone <acleone ~AT~ gmail.com>, 2009-02-03 */

#include "Tlc5940.h"

// Min values
int minr=100;
int ming=100;
int minb=0;
int minbright=80;

// Max values
int maxr=100;
int maxg=100;
int maxb=0;
int maxbright=100;

const int flicker=500;

// Serial parser

const int NUMBER_OF_FIELDS=9;
int fieldIndex=0;
int values[NUMBER_OF_FIELDS];


void setup()
{
  /* Call Tlc.init() to setup the tlc.
     You can optionally pass an initial PWM value (0 - 4095) for all channels.*/
  randomSeed(1235);
  Tlc.init();
  Tlc.clear();
  Serial.begin(9600);
}

/* This loop will create a Knight Rider-like effect if you have LEDs plugged
   into all the TLC outputs.  NUM_TLCS is defined in "tlc_config.h" in the
   library folder.  After editing tlc_config.h for your setup, delete the
   Tlc5940.o file to save the changes. */

/**
*
* red, green blue: between 0 and 4095
* brightness: between 0 and 100
*
*/
void set_candle(int number, int red, int green, int blue, float brightness)
{
  int channel;
  int ired, iblue, igreen;
  
  channel = number * 3;
  
  ired = 40*red; // max is 4095, so 40*100=4000 is good and we do not overflow
  igreen = 40*green;
  iblue = 40*blue;
  
  Tlc.set(channel, int(ired*brightness/100));
  Tlc.set(channel + 1, int(igreen*brightness/100));
  Tlc.set(channel + 2, int(iblue*brightness/100));

}

void loop()
{
    int r,g,b, bright;
    r = random (minr, maxr);
    g = random (ming, maxg);
    b = random (minb, maxb);
    bright=random(minbright,maxbright);
    
    set_candle(0, r, g, b, bright);
    set_candle(1, r, g, b, bright);
    set_candle(2, r, g, b, bright);
    set_candle(3, r, g, b, bright);
    set_candle(4, r, g, b, bright);
    Tlc.update();

    delay(flicker);

    // Read commands from serial
    fieldIndex=0;
    for (int i ; i<NUMBER_OF_FIELDS; i++)
    {
      values[i]=0;
    }
    while (Serial.available())
    {

      char ch = Serial.read();
  
      if (ch>='0' && ch<='9')
      {
        values[fieldIndex] = (values[fieldIndex] *10) + (ch -'0');
        
      }
      else if (ch==',')
      {
        Serial.print("Field: ");
        Serial.println(fieldIndex);
        Serial.print("Value: ");
        Serial.println(values[fieldIndex]);
        if (fieldIndex < NUMBER_OF_FIELDS - 1)
        {
          fieldIndex ++;
        }
      }
      else if (ch='g') // go !
      {
        // values[0]=candle
        minr=values[1];
        maxr=values[2];
        ming=values[3];
        maxg=values[4];
        minb=values[5];
        maxb=values[6];
        minbright=values[7];
        maxbright=values[8];
        // Parse results
        Serial.println("Setting");
        
        r = random (minr, maxr);
    g = random (ming, maxg);
    b = random (minb, maxb);
    bright=random(minbright,maxbright);
    
    set_candle(0, r, g, b, bright);
    set_candle(1, r, g, b, bright);
    set_candle(2, r, g, b, bright);
    set_candle(3, r, g, b, bright);
    set_candle(4, r, g, b, bright);
    Tlc.update();
    for (int i ; i<NUMBER_OF_FIELDS; i++)
    {
      values[i]=0;
    }
      }
      else
      {
        // Do nothing not a command
      }
    }
    
    
    // Ends read from serial

}
// 1,90,90,30,30,10,10,90,100g
// 1,20,20,90,90,10,10,90,100g
// 1,20,20,10,10,90,90,50,100g
