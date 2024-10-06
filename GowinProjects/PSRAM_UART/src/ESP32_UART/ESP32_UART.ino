#include <HardwareSerial.h>

HardwareSerial GwSerial(1); // define a Serial para UART1
const int GwSerialRX = 16;
const int GwSerialTX = 17;
int led = 2;
//bool communicationFinished = true;

void setup() 
{
    Serial.begin(115200); // Monitor serial
    // inicializar a Serial nos pinos definidos
    GwSerial.begin(115200, SERIAL_8N1, GwSerialRX, GwSerialTX);
    pinMode(led, OUTPUT);

    Serial.println("Sending message in 5 seconds...");
    delay(5000); // Delay para simular o envio após 5 segundos

    // Definir a mensagem de 4 bytes
    uint8_t message[4];
    message[0] = 0x52;    // Letra 'R'
    message[1] = 0x00;    // Most significant byte
    message[2] = 0x12;    // Middle significant byte
    message[3] = 0x34;    // Least significant byte

    Serial.print("Message: ");

    Serial.print("0x");

    for (int i = 0; i < 4; i++) {

        Serial.print(message[i], HEX);
        if (i < 3) {
            Serial.print(" ");
        }
    }
    Serial.println(); // Quebra de linha após imprimir a mensagem

    // Enviar a mensagem via UART
    GwSerial.write(message, 4);

}

void loop() 
{
  delay(500);
  digitalWrite(led, HIGH);
  delay(500);
  digitalWrite(led, LOW);
    // Código de comunicação UART (se necessário para leitura ou novas transmissões)
}
