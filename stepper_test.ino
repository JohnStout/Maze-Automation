
/*
 Stepper Motor Control - speed control

 This program drives a unipolar or bipolar stepper motor.
 The motor is attached to digital pins 8 - 11 of the Arduino.
 A potentiometer is connected to analog input 0.

 The motor will rotate in a clockwise direction. The higher the potentiometer value,
 the faster the motor speed. Because setSpeed() sets the delay between steps,
 you may notice the motor is less responsive to changes in the sensor value at
 low speeds.

 Created 30 Nov. 2009
 Modified 28 Oct 2010
 by Tom Igoe

 */
#include <Servo.h>
#include <Stepper.h>

const int stepsPerRevolution = 200;  // change this to fit the number of steps per revolution
// for your motor


Stepper myFirstStepper(stepsPerRevolution, A0,11,2,12);
Stepper mySecondStepper(stepsPerRevolution, 7,4,5,6);
Servo myservo1;  // create servo object to control a servo
Servo myservo2;  // create servo object to control a servo
Servo myservo3;  // create servo object to control a servo

int inPin1 = 14;
int inPin2 = 16;
int inPin3 = 19;

int stepCount = 0;  // number of steps the motor has taken
int pos = 0;
int val1 = 0,val2=0,val3=0;
void setup() {
  pinMode(inPin1, INPUT);
  pinMode(inPin2, INPUT); 
  pinMode(inPin3, INPUT); 

  Serial.begin(9600); // open the serial port at 9600 bps:

  myservo1.attach(A7);  // attaches the servo on pin 9 to the servo object
  myservo2.attach(A9);  // attaches the servo on pin 9 to the servo object
  myservo3.attach(A8);  // attaches the servo on pin 9 to the servo object

}

void loop() {

//  val1 = digitalRead(inPin1);   // read the input pin
//  Serial.print("val1=");
//  Serial.print(val1,DEC);
//  val2 = digitalRead(inPin2);   // read the input pin
//  Serial.print(" val2=");
//  Serial.print(val2,DEC);
//  val3 = digitalRead(inPin3);   // read the input pin
//  Serial.print(" val3=");
//  Serial.println(val3,DEC);
  
  int sensorReading = 1023;
  int motorSpeed = 10;//map(sensorReading, 0, 1023, 0, 100);
  // set the motor speed:
  if (motorSpeed > 0) {
    myFirstStepper.setSpeed(150);
    myFirstStepper.step(stepsPerRevolution );
    mySecondStepper.setSpeed(150);
    mySecondStepper.step(stepsPerRevolution);
  }
   //myservo1.write(180);              // tell servo to go to position in variable 'pos'
   //myservo1.write(0);              // tell servo to go to position in variable 'pos'


  if(pos==0 )
  {
    myservo1.write(180);              // tell servo to go to position in variable 'pos'
    myservo2.write(180);              // tell servo to go to position in variable 'pos'
    myservo3.write(180);              // tell servo to go to position in variable 'pos'
    pos=1;
    delay(500);
  }
  else
  if(pos==1 )
  {
    myservo1.write(0);              // tell servo to go to position in variable 'pos'
    myservo2.write(0);              // tell servo to go to position in variable 'pos'
    myservo3.write(0);              // tell servo to go to position in variable 'pos'
    pos=0;   
    delay(500);
  }

  
}


