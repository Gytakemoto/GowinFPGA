#include <HardwareSerial.h>

HardwareSerial GwSerial(1); // define a Serial for UART1
const int GwSerialRX = 16;
const int GwSerialTX = 17;
bool communicationFinished = true;

void setup() 
{
  Serial.begin(115200); //Monitor serial
	// initialize the Serial to the pins
    GwSerial.begin(115200, SERIAL_8N1, GwSerialRX, GwSerialTX);

    Serial.println("Ready to send...");
}

void loop() 
{
  while (GwSerial.available()) {
    char receivedChar = GwSerial.read();
    Serial.print(receivedChar);
    communicationFinished = false; // A comunicação ainda está ocorrendo
  }

  // Ler dados do monitor serial e enviar para a porta serial da FPGA
  while (Serial.available()) {
    char receivedChar = Serial.read();
    GwSerial.write(receivedChar);
    communicationFinished = false; // A comunicação ainda está ocorrendo
  }

  // Adiciona uma quebra de linha no monitor serial quando a comunicação UART é finalizada
  if (communicationFinished == false && GwSerial.available() == 0 && Serial.available() == 0) {
    Serial.println(); // Imprime uma quebra de linha
    communicationFinished = true; // Define como verdadeiro para a próxima comunicação
  }
}