#include <SoftwareSerial.h>

SoftwareSerial BTSerial(0, 1); // RX | TX

// motor one
int enA = 2; 
int in1 = 3; 
int in2 = 4;
// motor two
int enB = 5; 
int in3 = 6;
int in4 = 7; 

int enablePin = 9;
int motor1Pin = 11;
int motor2Pin = 10;

//int enA = 2; 
//int in1 = 5; 
//int in2 = 3;
// motor two
//int enB = 0; 
//int in3 = 4;
//int in4 = 1; 


String command;
boolean commandStarted = false;

void setup() {
  Serial.begin(9600);
  BTSerial.begin(9600); 
 // set all the motor control pins to outputs
  pinMode(enA, OUTPUT);
  pinMode(enB, OUTPUT);
  pinMode(in1, OUTPUT);
  pinMode(in2, OUTPUT);
  pinMode(in3, OUTPUT);
  pinMode(in4, OUTPUT);
  
  pinMode(enablePin, OUTPUT);
  pinMode(motor1Pin, OUTPUT);
  pinMode(motor2Pin, OUTPUT);
  
  digitalWrite(enablePin, HIGH);

}

void loop() {
	getCommand();
}


/* 
This function reads the serial port and checks for the start character '#'
if the start character if found it will add all received characters to 
the command buffer until it receives the end command ';' When the end 
command is received the commandCompleted() function is called.
if a second start character is found before an end character then the buffer
is cleared and the process starts over. 
*/
void getCommand() {
   while (Serial.available()) {
    char newChar = (char)Serial.read();
    if (newChar == '!') {
      commandStarted = true;
      command = "\0";
    } else if (newChar == ';') {
      commandStarted = false;
      commandCompleted();
      command = "\0";
    } else if (commandStarted == true) {
      command += newChar;
    }
  }
}

/*
This function takes the completed command and checks it against a list
of available commands and executes the appropriate code.  Add extra 'if' 
statements to add commands with the code you want to execute when that 
command is received. It is recommended to create a function for a command
if there are more than a few lines of code for as in the 'off' example.
*/
void commandCompleted() {
  if (command == "left") {
  	left(250,0);
	right(250,1);
  }
  if (command == "right") {
	right(250,0);
	left(250,1);
  }
  if (command == "forward") {
  	left(250,0);
  	right(250,0);
  }
  if (command == "reverse") {
  	left(225,1);
  	right(225,1);
  }
  if (command == "spinneron") {
    Serial.print("Spinner on.");
    digitalWrite(motor1Pin, HIGH);
    digitalWrite(motor2Pin, LOW);
  }
  if (command == "spinneroff") {
    Serial.print("Spinner off.");
    digitalWrite(motor1Pin, LOW);
    digitalWrite(motor2Pin, LOW);
  }
  if (command == "off") {
    off();
  }
}

void left(int speed, int direction) {
    // turn on motor A
    if (direction == 1) {
    	//motor reverse
		digitalWrite(in1, LOW);
		digitalWrite(in2, HIGH);
		analogWrite(enA, speed);
		Serial.print("Left wheel reverse");
	}
	else
	{
		//motor forward
		digitalWrite(in1, HIGH);
		digitalWrite(in2, LOW);
		analogWrite(enA, speed);
		Serial.print("Left wheel forward");
	}
}

void right(int speed, int direction) {
  	// turn on motor B
  	if (direction == 1) {
  		//motor reverse
		digitalWrite(in3, LOW);
		digitalWrite(in4, HIGH);
		analogWrite(enB, speed);
		Serial.print("Right wheel forward");
  	}
  	else
  	{
  		//motor forward
		digitalWrite(in3, HIGH);
		digitalWrite(in4, LOW);
		analogWrite(enB, speed);
		Serial.print("Right wheel forward");
  	}	
}


/*
Use a separate function like this when there are more than just a few
lines of code.  This will help maintain clean easy to read code.
*/
void off() {
  // now turn off motors
  digitalWrite(in1, LOW);
  digitalWrite(in2, LOW);  
  digitalWrite(in3, LOW);
  digitalWrite(in4, LOW);
  Serial.print("Motors turned off");
}


