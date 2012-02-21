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
    
    // Up to date source:
    // http://code.google.com/p/tlc5940arduino/
    
/*
 * IRremote: IRrecvDemo - demonstrates receiving IR codes with IRrecv
 * An IR detector/demodulator must be connected to the input RECV_PIN.
 * Version 0.1 July, 2009
 * Copyright 2009 Ken Shirriff
 * http://arcfn.com
 *
 * data pin for IR is pin 2
 *
 */
 
 // Problems using IRremote AND TLC: http://arduino.cc/forum/index.php?action=printpage;topic=61412.0

#include "Tlc5940.h"
//#include <IRremote.h>

int RECV_PIN = 2;

//IRrecv irrecv(RECV_PIN);


const int numcandles = 5;

struct candledata {
  // Min values
  unsigned char minr;
  unsigned char ming;
  unsigned char minb;
  unsigned char minbright;
  
  // Max values
  unsigned char maxr;
  unsigned char maxg;
  unsigned char maxb;
  unsigned char maxbright;
  
  int flicker;
};

// Program steps
struct pstep{
  unsigned char r;
  unsigned char g;
  unsigned char b;
  unsigned char bright;
  int delayafter;
};

// Program position
int ppos = 0;

struct candledata candle[numcandles];

const int debugprint = 1;

int program = 1;

const int flicker = 500;

// Serial parser

const int NUMBER_OF_FIELDS=9;
int fieldIndex=0;
int values[NUMBER_OF_FIELDS];

int set = 0;

void setup()
{

  //irrecv.enableIRIn(); // Start the receiver
  
  randomSeed(1235);
  Tlc.init();
  Tlc.clear();
  if (debugprint)
    Serial.begin(9600);
  set = 0;
  
  // Set candles
  for (int i = 0; i < numcandles; i++){
      candle[i].minr=50;
      candle[i].maxr=50;
      candle[i].ming=50;
      candle[i].maxg=50;
      candle[i].minb=50;
      candle[i].maxb=50;
      candle[i].minbright=50;
      candle[i].maxbright=50;
  }
}

/** The additional under-floor rgb strip
* Two colors are arduino pins, one is from the chip
* (want more pins !)
*
* brightness: between 0 and 100
**/
/*void set_floor(int red, int green, int blue, int brightness)
{
  int ired, iblue, igreen;
  
  ired = int (40 * red / 100 * brightness); 
  igreen = int (40 * green / 100 * brightness);
  iblue = int (40 * blue / 100 * brightness);
  
  Tlc.set(15, map(igreen,0,100,0,4095));
}*/


/**
*
* red, green blue: between 0 and 100
* brightness: between 0 and 100
*
*/
void set_candle(unsigned char number, int red, int green, int blue, int brightness)
{
  int channel;
  int ired, iblue, igreen;

  if ((number < 0) || (number >= numcandles))
    return;

  
  // max is 4095, so 40*100=4000 is good and we do not overflow
  channel = number * 3;

  
  
  ired = int (40 * red / 100 * brightness); 
  igreen = int (40 * green / 100 * brightness);
  iblue = int (40 * blue / 100 * brightness);

  if (ired < 0)
    ired = 0;
  if (ired > 4095)
    ired = 4095;
    
  if (iblue < 0)
    iblue = 0;
  if (iblue > 4095)
    iblue = 4095;
    
  if (igreen < 0)
    igreen = 0;
  if (igreen > 4095)
    igreen = 4095;    
  
  
  if (debugprint){
      Serial.print("Number: "); 
      Serial.println(number);
      Serial.print("First channel: "); 
      Serial.println(channel);
      Serial.print("Set candle red: "); 
      Serial.println(ired);
      Serial.print("Set candle green: "); 
      Serial.println(igreen);
      Serial.print("Set candle blue: "); 
      Serial.println(iblue);
      Serial.print("bright: "); 
      Serial.println(brightness);
  }
  
  Tlc.set(channel, ired);
  Tlc.set(channel + 1, igreen);
  Tlc.set(channel + 2, iblue);

}

/**
* 
* Do some random calculation for new candle values. Also update the candle
*
* number: the cnadle to sets
*
**/
void random_candle(int number)
{
    int r,g,b, bright;
    if (debugprint){
        Serial.println("Setting");
        Serial.print("Number: ");
        Serial.println(number);
        Serial.print("R: ");
        Serial.println(candle[number].minr);
        Serial.print("G: ");
        Serial.println(candle[number].ming);
        Serial.print("B: ");
        Serial.println(candle[number].minb);
    }
          
    r = random (candle[number].minr, candle[number].maxr);
    g = random (candle[number].ming, candle[number].maxg);
    b = random (candle[number].minb, candle[number].maxb);
    bright=random(candle[number].minbright,candle[number].maxbright);
          
    set_candle(number, r, g, b, bright);
}



/** Simulate fire
*
* red from: 100 to 100
* green from: 50 to 0
* blue: 0
* bright: from 0 to 100, there is not much difference from 40 to 100
*
* ppos: Program position
* rmod: red modification, will be added
* gmod: green modification, will be added
* bmod: blue modification, will be added
* brightmod: bright modification, will be added
* speedmod: added to delay. + will be slower, - faster
*
*
* return: the new ppos
**/
int fire(int ppos, int rmod, int gmod, int bmod, int brightmod, int speedmod)
{
  const int length = 16;
  struct pstep program[length] = {{100,80,10,100,70},
                              {100,70,10,100,7},
                              {100,50,10,100,55},
                              {100,30,10,100,40},
                              {100,35,3,100,4},
                              {100,10,10,80,50},
                              {100,30,10,100,40},
                              {100,50,10,100,40},
                              
                              {100,90,5,80,70},
                              {100,80,5,80,7},
                              {100,60,5,80,55},
                              {100,40,5,80,40},
                              {100,35,3,80,4},
                              {100,20,5,70,50},
                              {100,40,5,80,40},
                              {100,60,5,80,40}
                            };
  struct pstep command;
  if (debugprint){
      Serial.print("Program fire\n");
  }  
  ppos = ppos + 1;
  if (ppos >= length)
    ppos = 0;
    
  command = program[ppos];
  
  set_candle(2,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(1,command.r-10+rmod, command.g-10+gmod, command.b+bmod, command.bright-30+brightmod);
  set_candle(3,command.r-10+rmod, command.g-10+gmod, command.b+bmod, command.bright-30+brightmod);
  set_candle(0,command.r-20+rmod, command.g-20+gmod, command.b+bmod, command.bright-60+brightmod);
  set_candle(4,command.r-20+rmod, command.g-20+gmod, command.b+bmod, command.bright-60+brightmod);

  Tlc.update();
  delay(command.delayafter+speedmod);

  return ppos;  
}

/** Simulate heart pumping
*
*
* ppos: Program position
* rmod: red modification, will be added
* gmod: green modification, will be added
* bmod: blue modification, will be added
* brightmod: bright modification, will be added
* speedmod: added to delay. + will be slower, - faster
*
*
* return: the new ppos
**/
int pump(int ppos, int rmod, int gmod, int bmod, int brightmod, int speedmod)
{
  const int length = 22;
  struct pstep program[length] = {{50,50,50,0,35},
                                  {50,50,50,30,35},
                                  {50,50,50,50,35},
                                  {50,50,50,70,35},
                                  {50,50,50,90,35},
                                  {50,50,50,100,50},
                                  {50,50,50,90,35},
                                  {50,50,50,70,35},
                                  {50,50,50,50,35},
                                  {50,50,50,30,45},
                                  {50,50,50,0,45},
                                  
                                  {50,50,50,0,35},
                                  {50,50,50,30,35},
                                  {50,50,50,50,35},
                                  {50,50,50,70,35},
                                  {50,50,50,90,35},
                                  {50,50,50,100,50},
                                  {50,50,50,90,35},
                                  {50,50,50,70,35},
                                  {50,50,50,50,45},
                                  {50,50,50,30,45},
                                  {50,50,50,0,800},
                                  
                                  
                            };
  struct pstep command;
  if (debugprint){
      Serial.print("Program pump ");
      Serial.print(ppos);
      Serial.print("\n");
  }  
  ppos = ppos + 1;
  if (ppos >= length)
    ppos = 0;
    
  command = program[ppos];
  
  set_candle(0,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(1,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(2,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(3,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(4,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);

  Tlc.update();
  delay(command.delayafter+speedmod);

  return ppos;  
}


/** Simulate lightning
*
*
* ppos: Program position
* rmod: red modification, will be added
* gmod: green modification, will be added
* bmod: blue modification, will be added
* brightmod: bright modification, will be added
* speedmod: added to delay. + will be slower, - faster
*
*
* return: the new ppos
**/
int lightning(int ppos, int rmod, int gmod, int bmod, int brightmod, int speedmod)
{
  const int length = 19;
  struct pstep program[length] = {{0,0,0,0,2000},
                                  {100,100,100,100,20},
                                  {0,0,0,0,6000},
                                  {100,100,100,100,20},
                                  {0,0,0,0,60},
                                  {100,100,100,100,20},
                                  {0,0,0,0,3000},
                                  
                                  {100,100,100,100,20},
                                  {0,0,0,0,3000},
                                  {100,100,100,100,20},
                                  {0,0,0,0,90},
                                  {100,100,100,100,20},
                                  {0,0,0,0,2000},
                                  
                                  {100,100,100,100,20},
                                  {0,0,0,0,9000},
                                  {100,100,100,100,20},
                                  {0,0,0,0,160},
                                  {100,100,100,100,20},
                                  {0,0,0,0,4000},
                                  
                            };
  struct pstep command;
  if (debugprint){
      Serial.print("Program lightning");
      Serial.print(ppos);
      Serial.print("\n");
  }  
  ppos = ppos + 1;
  if (ppos >= length)
    ppos = 0;
    
  command = program[ppos];
  
  set_candle(0,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(1,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(2,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(3,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(4,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);

  Tlc.update();
  delay(command.delayafter+speedmod);

  return ppos;  
}

/** Simulate an alert
*
*
* ppos: Program position
* rmod: red modification, will be added
* gmod: green modification, will be added
* bmod: blue modification, will be added
* brightmod: bright modification, will be added
* speedmod: added to delay. + will be slower, - faster
*
*
* return: the new ppos
**/
int alert(int ppos, int rmod, int gmod, int bmod, int brightmod, int speedmod)
{
  struct pstep command;
  if (debugprint){
      Serial.print("Program alert\n");
  }  
  ppos = ppos + 1;
  if (ppos >= numcandles)
    ppos = 0;
    
  //command = program[ppos];
  
  for (int i = 0; i< numcandles; i ++)
  {
    if (i != ppos)
      set_candle(i,0,0,0,0);
  }
  
  set_candle(ppos,100 + rmod, 100 + gmod, 100 + bmod, 100 + brightmod);
  
  Tlc.update();
  delay(100+speedmod);

  return ppos;  
}

/** Simple test pattern
*
*
* ppos: Program position
* rmod: red modification, will be added
* gmod: green modification, will be added
* bmod: blue modification, will be added
* brightmod: bright modification, will be added
* speedmod: added to delay. + will be slower, - faster
*
*
* return: the new ppos
**/
int test(int ppos, int rmod, int gmod, int bmod, int brightmod, int speedmod)
{
  const int length = 2;
  struct pstep program[length] = {{100,0,0,100,1000},
                                  {100,0,0,0,0}             
                            };
  struct pstep command;
  if (debugprint){
      Serial.print("Program test ");
      Serial.print(ppos);
      Serial.print("\n");
  }  
  ppos = ppos + 1;
  if (ppos >= length)
    ppos = 0;
    
  command = program[ppos];
  
  set_candle(0,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(1,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(2,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(3,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);
  set_candle(4,command.r+rmod, command.g+gmod, command.b+bmod, command.bright+brightmod);

  Tlc.update();
  delay(command.delayafter+speedmod);

  return ppos;  
}

/** Read IR and return the key code.
* This function is for the remote control Model 23057
* 
*
**/
/*
int read_ir(int old){
  int val;
  decode_results results;
  
  // Read IR
  if (irrecv.decode(&results)) {
    //  Serial.println(results.value, HEX);
    irrecv.resume(); // Receive the next value
    val = results.value;
    
    // Somtimes button presses can generate a number + 0x800
    if (val > 0x800){
      val = val - 0x800;
    }
    return val;
  }

  return old;    

}*/

void loop()
{
    switch (program){
      case(1):
        ppos = fire(ppos,100,-90,-90,0,0);
        break;
      case (2):
        ppos = pump(ppos,-100,-100,100,0,0);
        break;
      case (3):
        ppos = lightning(ppos,-100,-100,100,0,0);
        break;
      case (4):
        ppos = alert(ppos,0,0,-40,0,0);
        break;
      case (9):
        ppos = test(ppos,0,0,0,0,0);
        break;
   }
    
    //set_special_candle(0, 100, 0, 100);
    
    
   //program = read_ir(program);
    
}

