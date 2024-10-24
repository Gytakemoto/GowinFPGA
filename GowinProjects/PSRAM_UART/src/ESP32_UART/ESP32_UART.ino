#include <HardwareSerial.h>

HardwareSerial GwSerial(1); // define a Serial para UART1
const int GwSerialRX = 16;
const int GwSerialTX = 17;
int led = 2;
int test = 1;
int step;
#define START 0
#define READ_WRITE 1
#define ADDRESS 2
#define MSG 3
#define SEND 4
bool reading = false;
bool writing = false;
int refresh = 0;

// Definir a mensagem de 4 ou 6 bytes
uint8_t message[6];
int messageLength = 0; // variável para armazenar o comprimento da mensagem

// Cada char é equivalente a 1 byte
char incomingBytes[6];

void setup() 
{
    Serial.begin(115200); // Monitor serial
    GwSerial.begin(115200, SERIAL_8N1, GwSerialRX, GwSerialTX); // Gowin Serial
    Serial.setTimeout(1000);
    pinMode(led, OUTPUT);
}

void loop() 
{
    switch (step) {

        case START: {
            if (GwSerial.available() > 0) {
                // Buffer para armazenar a mensagem lida
                char receivedMessage[10];
                int i = 0;

                // Ler os bytes disponíveis na UART1
                while (GwSerial.available() > 0 && i < sizeof(receivedMessage) - 1) {
                    receivedMessage[i] = GwSerial.read();  // Lê cada byte
                    i++;
                }

                receivedMessage[i] = '\0';  // Terminar a string

                // Imprimir a mensagem lida no formato hexadecimal
                Serial.print("A mensagem lida foi: ");
                for (int j = 0; j < i; j++) {
                    Serial.printf("%02X ", receivedMessage[j]);
                }
                Serial.println();
            }
            else {
                refresh = refresh + 1;
                if (refresh == 1) {
                    Serial.println();
                    Serial.println("Begin UART communication? (y/n)");
                }
                else if (refresh > 1 && refresh < 8) {
                    Serial.print(".");
                }
                else refresh = 0;

                Serial.readBytesUntil('\n', incomingBytes, 1);
            
                if (Serial.available() > 0) {
                    Serial.println(incomingBytes);

                    if(incomingBytes[0] == 'y' || incomingBytes[0] == 'Y'){
                        step = READ_WRITE;
                        Serial.println("User selected to begin communication");
                        refresh = 0;
                    }
                    else if(incomingBytes[0] == 'n' || incomingBytes[0] == 'N'){
                        Serial.println("User selected NOT to begin communication");
                    }
                }
            }       
        }
        break;

        case READ_WRITE: {
            refresh = refresh + 1;
            if (refresh == 1) {
                Serial.println();
                Serial.println("Perform read or write operation? (w/r)");
            }
            else if (refresh > 1 && refresh < 8) {
                Serial.print(".");
            }
            else refresh = 0;

            Serial.readBytesUntil('\n', incomingBytes, 1);

            if (Serial.available() > 0) {
                if (incomingBytes[0] == 'w' || incomingBytes[0] == 'W') {
                    writing = true;
                    reading = false;
                    message[0] = 0x57; // Letra "W"
                    step = ADDRESS;
                    Serial.println();
                    Serial.println("User selected a write operation");
                    refresh = 0;
                }
                else if (incomingBytes[0] == 'r' || incomingBytes[0] == 'R') {
                    reading = true;
                    writing = false;
                    message[0] = 0x52; // Letra "R"
                    step = ADDRESS;
                    Serial.println();
                    Serial.println("User selected a read operation");
                    refresh = 0;
                }
            }
        }
        break;

        case ADDRESS: {
            refresh = refresh + 1;
            if (refresh == 1) {
                Serial.println();
                Serial.println("Enter the 22-bit address in HEX format (i.e 001234)");
            }
            else if (refresh > 1 && refresh < 8) {
                Serial.print(".");
            }
            else refresh = 0;

            Serial.readBytesUntil('\n', incomingBytes, 6);
            incomingBytes[6] = '\0'; // Garantir que a string tenha um terminador nulo

            if (Serial.available() > 0) {
                // Converter o endereço digitado de string para número hexadecimal
                long address = strtol(incomingBytes, NULL, 16);

                // Atribuir os 3 bytes do endereço ao message[]
                message[1] = (address >> 16) & 0xFF;
                message[2] = (address >> 8) & 0xFF;
                message[3] = address & 0xFF;

                Serial.println();
                Serial.print("O endereço digitado foi: ");
                Serial.println(address, HEX);

                if (reading) {
                    step = SEND;
                    refresh = 0;
                }
                else if (writing) {
                    step = MSG;
                    refresh = 0;
                }
            }
        }
        break;

        case MSG: {
            refresh = refresh + 1;
            if (refresh == 1) {
                Serial.println();
                Serial.println("Enter the 16-bit message in HEX format (i.e 1234)");
            }
            else if (refresh > 1 && refresh < 8) {
                Serial.print(".");
            }
            else refresh = 0;

            Serial.readBytesUntil('\n', incomingBytes, 4);
            incomingBytes[4] = '\0';

            if (Serial.available() > 0) {
                // Converter a mensagem de string para número hexadecimal
                long msg = strtol(incomingBytes, NULL, 16);

                // Atribuir os 2 bytes da mensagem ao message[]
                message[4] = (msg >> 8) & 0xFF;
                message[5] = (msg) & 0xFF;

                Serial.println();
                Serial.print("A mensagem digitada foi: ");
                Serial.println(msg, HEX);
                step = SEND;
            }
        }
        break;

        case SEND: {
            if (writing) {
                messageLength = 6;
            }
            else if (reading) {
                messageLength = 4;
            }

            // Enviar a mensagem via UART
            int sentBytes = GwSerial.write(message, messageLength);

            // Verificar se a quantidade de bytes enviados corresponde ao esperado
            if (sentBytes == messageLength) {
                Serial.println("Message sent successfully!");
            }
            else {
                Serial.println("Sending message...");
            }
            reading = false;
            writing = false;
            step = START; // Voltar ao início após o envio
        }
    }
}
