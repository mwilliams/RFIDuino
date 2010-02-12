#include <Ethernet.h>
#include "Dhcp.h"

#include <string.h>

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte server[] = { 208, 97, 167, 189 }; // Google
char code[10];
int  val = 0; 
int bytesread = 0; 

unsigned long lastRfidTagSent;

Client client(server, 80);

void setup()
{
  Serial.begin(2400);
  pinMode(2,OUTPUT);     // Set digital pin 2 as OUTPUT to connect it to the RFID /ENABLE pin 
  digitalWrite(2, LOW);  // Activate the RFID reader
  Serial.println("getting ip...");
  int result = Dhcp.beginWithDHCP(mac);  // Obtain an IP address via DHCP
  if(result == 1)
    Serial.println("Connected!");
  else
    Serial.println("Couldn't connect...");
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
      {                                  // if 10 digit read is complete 
        digitalWrite(2, HIGH);           // turn off the RFID reader to prevent it from reading any other tags
        SendTagToWebServer();
        digitalWrite(2, LOW);
        delay(1);
      }
    }
  }
}

void SendTagToWebServer(){

  uint8_t connectStatus;
  unsigned long now = millis();
  Serial.println(now);
  Serial.println(lastRfidTagSent);
  if ((now - lastRfidTagSent) > 5000) {
    if (client.connect()) {
      Serial.println("Connected! Sending Tag...");
      // Send the HTTP GET to the server
      client.print("GET ");
      client.print("/rfid/");
      client.print(code);
      client.print(" HTTP/1.1");
      client.println();
      client.println("Host: www.ultravoid.com");
      client.println();
  // Disconnect from the server
      client.flush();
      client.stop();
      Serial.println("Finished sending tag...");
      lastRfidTagSent = millis();
    } else {
  // Connection failed
      Serial.println(" - CONNECTION FAILED!");
    }
  }
}
