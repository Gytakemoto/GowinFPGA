#define START 0
#define SEND 1
#define SAMPLE_AFTER_MAX 0x3FFFFF

HardwareSerial GwSerial(1); // define a Serial para UART1
const int GwSerialRX = 16;
const int GwSerialTX = 17;
int led = 2;
int step = START;
uint8_t message[8];

void setup() {
  Serial.begin(115200); // Monitor serial
  GwSerial.begin(115200, SERIAL_8N1, GwSerialRX, GwSerialTX); // Gowin Serial
  pinMode(led, OUTPUT);

  // Configuração da mensagem fixa
  message[0] = 0x41; // Letra "A" (modo "a")
  message[1] = 0x54; // Letra "T" (Threshold)
  
  // Definir samples_after e samples_before
  int samples_after = 10; // Valor fixo para samples_after
  int samples_before = 10; // Valor fixo para samples_before

  // Adicionar samples_after à mensagem
  message[2] = (samples_after >> 16) & 0xFF; // Byte mais significativo
  message[3] = (samples_after >> 8) & 0xFF;  // Byte intermediário
  message[4] = samples_after & 0xFF;         // Byte menos significativo

  // Adicionar samples_before à mensagem
  message[5] = (samples_before >> 16) & 0xFF; // Byte mais significativo
  message[6] = (samples_before >> 8) & 0xFF;  // Byte intermediário
  message[7] = samples_before & 0xFF;         // Byte menos significativo
}

void loop() {
  switch (step) {
    case START:
      Serial.println("Waiting for 2 seconds...");
      delay(2000);
      step = SEND;
      break;

    case SEND:
      Serial.println("Sending predefined message...");
      int sentBytes = GwSerial.write(message, sizeof(message));

      if (sentBytes == sizeof(message)) {
        Serial.println("Message sent successfully!");
      } else {
        Serial.println("Failed to send the complete message.");
      }

      // Reiniciar o sistema ou manter o loop dependendo da aplicação
      step = START; 
      break;
  }
}
