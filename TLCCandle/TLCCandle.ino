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


// Program steps
// Programs handle all top candles identical. 
// top_ is for the top candles
// bot_ is the bottom light
struct pstep{
  unsigned char top_r;
  unsigned char top_g;
  unsigned char top_b;
  unsigned char top_bright;
  unsigned char bot_r;
  unsigned char bot_g;
  unsigned char bot_b;
  unsigned char bot_bright;
  int delayafter;
};

// Program position
int ppos = 0;


const int debugprint = 0;

int program = 1;


void setup()
{

  //irrecv.enableIRIn(); // Start the receiver
  
  randomSeed(1235);
  Tlc.init();
  Tlc.clear();
  if (debugprint)
    Serial.begin(9600);

}

/** The additional under-floor rgb strip
* Two colors are arduino pins, one is from the chip
* (want more pins !). The one is reversed 
*
* brightness: between 0 and 100
**/
void set_floor(int red, int green, int blue, int brightness)
{
  int ired, iblue, igreen;
  
  ired = red * brightness / 100;
  if (ired <0)
    ired = 0;
  if (ired > 100)
    ired = 100;
    
  igreen = green * brightness / 100;
  if (igreen <0)
    igreen = 0;
  if (igreen > 100)
    igreen = 100;
    
  iblue = blue * brightness / 100;
  if (blue <0)
    iblue = 0;
  if (iblue > 100)
    iblue = 100;
  
  //ired = map (red * brightness / 100, 0, 100, 0, 100);
  //igreen = map (green * brightness / 100, 0, 100, 0, 100);
  //iblue = map (blue * brightness / 100, 0, 100, 0, 100);
//  ired = int (40 * red / 100 * brightness); 
//  igreen = int (40 * green / 100 * brightness);
//  iblue = int (40 * blue / 100 * brightness);
  
  Tlc.set(15, map(igreen,0,100,4095, 0)); // Green
  analogWrite(5, map(ired,0,100,0,255)); // Red
  analogWrite(6, map(iblue,0,100,0,255)); //Blue
}


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
  struct pstep program[length] = {{100,80,10,100,100,80,10,50,70},
                              {100,70,10,100,100,70,10,50,7},
                              {100,50,10,100,100,50,10,50,55},
                              {100,30,10,100,100,30,10,50,40},
                              {100,35,3,100,100,35,3,50,4},
                              {100,10,10,80,100,10,10,40,50},
                              {100,30,10,100,100,30,10,50,40},
                              {100,50,10,100,100,50,10,50,40},
                              
                              {100,90,5,80,100,90,5,40,70},
                              {100,80,5,80,100,80,5,40,7},
                              {100,60,5,80,100,60,5,40,55},
                              {100,40,5,80,100,40,5,40,40},
                              {100,35,3,80,100,35,3,40,4},
                              {100,20,5,70,100,20,5,30,50},
                              {100,40,5,80,100,40,5,40,40},
                              {100,60,5,80,100,60,5,40,40}
                            };
  struct pstep command;
  if (debugprint){
      Serial.print("Program fire\n");
  }  
  ppos = ppos + 1;
  if (ppos >= length)
    ppos = 0;
    
  command = program[ppos];
  
  set_candle(2,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(1,command.top_r-10+rmod, command.top_g-10+gmod, command.top_b+bmod, command.top_bright-30+brightmod);
  set_candle(3,command.top_r-10+rmod, command.top_g-10+gmod, command.top_b+bmod, command.top_bright-30+brightmod);
  set_candle(0,command.top_r-20+rmod, command.top_g-20+gmod, command.top_b+bmod, command.top_bright-60+brightmod);
  set_candle(4,command.top_r-20+rmod, command.top_g-20+gmod, command.top_b+bmod, command.top_bright-60+brightmod);
  
  set_floor(command.bot_r+rmod, command.bot_g+gmod, command.bot_b+bmod, command.bot_bright+brightmod);

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
  struct pstep program[length] = {{50,50,50,0,50,50,50,0,35},
                                  {50,50,50,30,50,50,50,5,35},
                                  {50,50,50,50,50,50,50,10,35},
                                  {50,50,50,70,50,50,50,15,35},
                                  {50,50,50,90,50,50,50,20,35},
                                  {50,50,50,100,50,50,50,25,50},
                                  {50,50,50,90,50,50,50,20,35},
                                  {50,50,50,70,50,50,50,15,35},
                                  {50,50,50,50,50,50,50,10,35},
                                  {50,50,50,30,50,50,50,5,45},
                                  {50,50,50,0,50,50,50,0,45},
                                  
                                  {50,50,50,0,50,50,50,0,35},
                                  {50,50,50,30,50,50,50,5,35},
                                  {50,50,50,50,50,50,50,10,35},
                                  {50,50,50,70,50,50,50,15,35},
                                  {50,50,50,90,50,50,50,20,35},
                                  {50,50,50,100,50,50,50,25,50},
                                  {50,50,50,90,50,50,50,20,35},
                                  {50,50,50,70,50,50,50,15,35},
                                  {50,50,50,50,50,50,50,10,45},
                                  {50,50,50,30,50,50,50,5,45},
                                  {50,50,50,0,50,50,50,0,800},
                                  
                                  
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
  
  set_candle(0,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(1,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(2,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(3,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(4,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  
  set_floor(command.bot_r+rmod, command.bot_g+gmod, command.bot_b+bmod, command.bot_bright+brightmod);

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
  struct pstep program[length] = {{0,0,0,0,0,0,0,0,2000},
                                  {100,100,100,100,100,100,100,100,20},
                                  {0,0,0,0,0,0,0,0,6000},
                                  {100,100,100,100,100,100,100,100,20},
                                  {0,0,0,0,0,0,0,0,60},
                                  {100,100,100,100,100,100,100,100,20},
                                  {0,0,0,0,0,0,0,0,3000},
                                  
                                  {100,100,100,100,100,100,100,100,20},
                                  {0,0,0,0,0,0,0,0,3000},
                                  {100,100,100,100,100,100,100,100,20},
                                  {0,0,0,0,0,0,0,0,90},
                                  {100,100,100,100,100,100,100,100,20},
                                  {0,0,0,0,0,0,0,0,2000},
                                  
                                  {100,100,100,100,100,100,100,100,20},
                                  {0,0,0,0,0,0,0,0,9000},
                                  {100,100,100,100,100,100,100,100,20},
                                  {0,0,0,0,0,0,0,0,160},
                                  {100,100,100,100,100,100,100,100,20},
                                  {0,0,0,0,0,0,0,0,4000},
                                  
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
  
  set_candle(0,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(1,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(2,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(3,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(4,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  
  set_floor(command.bot_r+rmod, command.bot_g+gmod, command.bot_b+bmod, command.bot_bright+brightmod);

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
  int bot_bright;
  
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
  
  
  // for 5 candles:
  if (numcandles != 5)
    bot_bright = 0;
  else if ((ppos == 0) || (ppos == 4))
    bot_bright = 20;
  else if ((ppos == 1) || (ppos == 3))
    bot_bright = 50;  
  else if (ppos == 2)
    bot_bright = 100;  
  
  set_floor(50+rmod, 50+gmod, 50+bmod, bot_bright);
  
  Tlc.update();
  delay(1000+speedmod);

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
  struct pstep program[length] = {{100,0,0,100,100,0,0,100,1000},
                                  {100,0,0,0,0,0,0,0,1000}             
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
  
  set_candle(0,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(1,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(2,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(3,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  set_candle(4,command.top_r+rmod, command.top_g+gmod, command.top_b+bmod, command.top_bright+brightmod);
  
  set_floor(command.bot_r+rmod, command.bot_g+gmod, command.bot_b+bmod, command.bot_bright+brightmod);

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
        ppos = alert(ppos,0,-100,-100,0,0);
        break;
      case (9):
        ppos = test(ppos,0,0,0,0,0);
        break;
   }
    
    //set_special_candle(0, 100, 0, 100);
    
    
   //program = read_ir(program);
    
}

