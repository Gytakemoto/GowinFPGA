#include <HardwareSerial.h>

HardwareSerial GwSerial(1); // define a Serial para UART1
const int GwSerialRX = 16;
const int GwSerialTX = 17;
int led = 2;
int test = 1;

void setup() 
{
    Serial.begin(115200); // Monitor serial
    // inicializar a Serial nos pinos definidos
    GwSerial.begin(115200, SERIAL_8N1, GwSerialRX, GwSerialTX);
    pinMode(led, OUTPUT);

    Serial.println("Sending message in 5 seconds...");
    delay(2000); // Delay para simular o envio após 5 segundos

    // Definir a mensagem de 4 ou 6 bytes
    uint8_t message[6];
    int messageLength = 0; // variável para armazenar o comprimento da mensagem

    //Read operation
    if (test == 0) {
      message[0] = 0x52;    // Letra 'R'
      message[1] = 0x00;    // Most significant byte
      message[2] = 0x12;    // Middle significant byte
      message[3] = 0x34;    // Least significant byte
      messageLength = 4;
    }
    else if (test == 1) {
      message[0] = 0x57;    // Letra 'W'
      message[1] = 0x00;    // Most significant byte
      message[2] = 0x12;    // Middle significant byte
      message[3] = 0x34;    // Least significant byte
      message[4] = 0xAB;    // Most significant byte
      message[5] = 0xCD;    // Least significant byte
      messageLength = 6;
    }

    Serial.print("Message: 0x");

    // Ajustar o loop para o tamanho correto da mensagem
    for (int i = 0; i < messageLength; i++) {
        Serial.print(message[i], HEX);
        if (i < messageLength - 1) {
            Serial.print(" ");
        }
    }
    Serial.println(); // Quebra de linha após imprimir a mensagem

    // Enviar a mensagem via UART
    GwSerial.write(message, messageLength);
}

void loop() 
{
  delay(500);
  digitalWrite(led, HIGH);
  delay(500);
  digitalWrite(led, LOW);
    // Código de comunicação UART (se necessário para leitura ou novas transmissões)
}
