/* 
This code controls two stepper motors and one DC motor
using the Adafruit Shield V2

Some important notes:
      To stack a shield, you must also define it as a separate
      I2C address. To do so follow the link below. For this case,
      we soldered the right most gold plates allowing us to define
      the bottom shield as 0x61 and top shield as 0x60. Note that
      on their webpage, they say that you don't need a jumper, however
      you do still need a jumper. We cut the top plastic piece off of one
      then used it for the bottom shield so that the top shield would fit.

For use with the Adafruit Motor Shield v2 
---->	http://www.adafruit.com/products/1438
*/


#include <Wire.h>
#include <Adafruit_MotorShield.h>

// Create the motor shield object for the bottom shield
Adafruit_MotorShield AFMSbot1 = Adafruit_MotorShield(0x61); 
Adafruit_MotorShield AFMSbot2 = Adafruit_MotorShield(0x61);

// create motor shield object for the top shield
Adafruit_MotorShield AFMStop1 = Adafruit_MotorShield(0x60);

// Connect a stepper motor with 500 steps per revolution (1.8 degree)
// to motor port #2 (M3 and M4) and #1 (M1 and M2)
Adafruit_StepperMotor *myStepper1 = AFMSbot1.getStepper(500, 1);
Adafruit_StepperMotor *myStepper2 = AFMSbot2.getStepper(500, 2);
Adafruit_DCMotor *myMotor1        = AFMStop1.getMotor(1);

void setup() {
  Serial.begin(9600);           // set up Serial library at 9600 bps
  Serial.println("Stepper test!");

  AFMSbot1.begin();  // create with the default frequency 1.6KHz
  //AFMS1.begin(1000);  // OR with a different frequency, say 1KHz
  AFMSbot2.begin();  // create with the default frequency 1.6KHz
  //AFMS2.begin(1000);  // OR with a different frequency, say 1KHz
  AFMStop1.begin();
  
  myStepper1->setSpeed(100);  // 10 rpm 
  myStepper2->setSpeed(100);  // 10 rpm   
  myMotor1->setSpeed(100);
  myMotor1->run(FORWARD);
  myMotor1->run(RELEASE);
}

void loop() {
  Serial.println("Move motors forward");
  myStepper1->step(300,BACKWARD,SINGLE);
  myStepper2->step(300,BACKWARD,SINGLE);
  myMotor1->run(BACKWARD);
  delay(2);

  Serial.println("Move motors backward");
  myStepper1->step(300,FORWARD,SINGLE);
  myStepper2->step(300,FORWARD,SINGLE);
  myMotor1->run(FORWARD);
  delay(2);
  
  
  /*
  myMotor->step(500,FORWARD,SINGLE);
  delay(2);
  Serial.println("Single coil steps");
  myMotor->step(100, FORWARD, SINGLE); 
  myMotor->step(100, BACKWARD, SINGLE); 

  Serial.println("Double coil steps");
  myMotor->step(100, FORWARD, DOUBLE); 
  myMotor->step(100, BACKWARD, DOUBLE);
  
  Serial.println("Interleave coil steps");
  myMotor->step(100, FORWARD, INTERLEAVE); 
  myMotor->step(100, BACKWARD, INTERLEAVE); 
*/
  /*
  Serial.println("Microstep steps");
  myMotor->step(50, FORWARD, MICROSTEP); 
  myMotor->step(50, BACKWARD, MICROSTEP);
  */
}
