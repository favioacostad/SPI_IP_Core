/*###########################################################################
//# G0B1T: HDL SERIAL COMMUNICATION PROTOCOLS. 2020.
//###########################################################################
//# Copyright (C) 2020. F.A.Acosta David   (FAD) fa.acostad@uniandes.edu.co
//# 
//# This program is free software: you can redistribute it and/or modify
//# it under the terms of the GNU General Public License as published by
//# the Free Software Foundation, version 3 of the License.
//#
//# This program is distributed in the hope that it will be useful,
//# but WITHOUT ANY WARRANTY; without even the implied warranty of
//# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//# GNU General Public License for more details.
//#
//# You should have received a copy of the GNU General Public License
//# along with this program.  If not, see <http://www.gnu.org/licenses/>
//#########################################################################*/
//===========================================================================
//  LIBRARIES
//===========================================================================
#include <SPI.h>

//===========================================================================
//  VARIABLE Declarations
//===========================================================================
//////////// READ ////////////
unsigned char dataRead;
unsigned char comingData;
byte newData;
//////////// WRITE ////////////
unsigned char dataWrite = '0';

//===========================================================================
//  SETUP Coding
//===========================================================================
// Setup code here, to run once
void setup() 
{
  // Opens serial communications and waits for port to open
  Serial.begin(115200);
  
  digitalWrite(SS, HIGH);  // Ensures SS stays high for now

  // Puts SCK, MOSI, SS pins into output mode
  // Also puts SCK, MOSI into LOW state, and SS into HIGH state.
  // Then puts SPI hardware into Master mode and turns SPI on
  SPI.begin();
  
  // Initializes the SPI bus using the defined SPISettings
  SPI.beginTransaction(SPISettings(20000000, MSBFIRST, SPI_MODE3));

  // Slows down the master a bit
  SPI.setClockDivider(SPI_CLOCK_DIV2);

  // Sets MISO pin mode
  pinMode(MISO,INPUT);

  // Gives the device time to set up
  delay(100);
}

//===========================================================================
//  LOOP Coding
//===========================================================================
// Main code here, to run repeatedly
void loop() 
{
  digitalWrite(SS, LOW);  // Sets the SS pin to LOW
  SPI.transfer(dataWrite);  // Sends data to the slave

  dataRead = dataWrite;

  newData = shiftIn(MISO,SCK,MSBFIRST); // Shifts in a byte of data one bit at a time
  comingData = SPI.transfer(0xFF);  // Reads data coming from slave MISO port

  digitalWrite(SS, HIGH); // Sets the SS pin HIGH

  // Prints out the data coming from the slave into the serial window
  Serial.print("Dec: ");
  Serial.print(comingData); 
  Serial.print(" Bin: ");
  bitArray(comingData);
  Serial.println(" ");

  dataWrite += 1; // Adds 1 for the data to send through MOSI port
  delay(500);
}

//===========================================================================
//  FUNCTIONS
//===========================================================================
// Changes the format from decimal to a binary array
void bitArray (unsigned char uint)
{
  int counter = 0;
  unsigned char binaryDigit;
  while (counter < 8)
  {
    if (uint & (1 << (7 - counter)))
    {
      binaryDigit = 1;
    }
    else
    {
      binaryDigit = 0;
    }
    Serial.print(binaryDigit);
    counter += 1;
  }
}
