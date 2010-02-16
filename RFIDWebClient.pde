#include <Ethernet.h>
#include "Dhcp.h"
#include <string.h>

byte mac[]            = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte server[]         = { 208, 97, 167, 189 }; // should be the IP address of the coffeeHostName
char coffeeHostName[] = "www.ultravoid.com";

boolean useDHCP = true;
byte ip[]       = {10, 0, 1, 10};
byte gateway[]  = {10, 0, 1, 1};

char code[10];
int  val = 0; 
int bytesread = 0; 
char lastCode[10];

unsigned long resendRate = 5000;
unsigned long lastRfidTagSent = 0;
unsigned long anotherLast = 0;

Client client(server, 80);

void setup()
{
  Serial.begin(2400);
  pinMode(2,OUTPUT);     // Set digital pin 2 as OUTPUT to connect it to the RFID /ENABLE pin 
  digitalWrite(2, LOW);  // Activate the RFID reader
  Serial.println("getting ip...");

  if(useDHCP == true) {
    int result = Dhcp.beginWithDHCP(mac);  // Obtain an IP address via DHCP
    if(result == 1)
      Serial.println("Connected!");
    else
      Serial.println("Couldn't connect...");
  }
  else {
    Ethernet.begin(mac, ip, gateway);
    Serial.println("done connecting");
  }   
}

void loop()
{
  if(Serial.available() > 0) {  // if data available from reader 
    if((val = Serial.read()) == 10) 
    {   // check for header 
      bytesread = 0; 
      while(bytesread<10) 
      { // read 10 digit code 
        if( Serial.available() > 0) 
        { 
          val = Serial.read(); 
          if((val == 10)||(val == 13)) 
          { // if header or stop bytes before the 10 digit reading 
            break;                       // stop reading 
          } 
          code[bytesread] = val;         // add the digit           
          bytesread++;                   // ready to read next digit  
        } 
      }  
      if(bytesread == 10) 
      {                                 
        digitalWrite(2, HIGH);           // turn off RDIF reader
        SendTagToWebServer();
        digitalWrite(2, LOW);
        delay(1);
      }
    }
  }
}

void SendTagToWebServer() {
  char* codePtr;
  char* lastCodePtr;
  codePtr = code;
  lastCodePtr = lastCode;
  int sameCode = strcmp(codePtr, lastCodePtr);
  unsigned long now = millis();

  // if current code isn't the same and time lapsed > 5000, send it
  if(sameCode == 0 && ((now - anotherLast) < resendRate)) {
    Serial.println("same code as before, not sending");
  }
  else  {
    if (client.connect()) {
      Serial.println("Sending Tag...");
      client.print("GET ");
      client.print("/rfid/");
      client.print(code);
      client.print(" HTTP/1.1");
      client.println();
      client.print("Host: ");
      client.println(coffeeHostName);
      client.println();
      client.flush();
      client.stop();
      Serial.println("Finished sending tag...");
      anotherLast = millis();
      Serial.println(lastRfidTagSent);
      strcpy(lastCode, codePtr);
    } else {
      Serial.println(" - CONNECTION FAILED!");
    }
  }
}
