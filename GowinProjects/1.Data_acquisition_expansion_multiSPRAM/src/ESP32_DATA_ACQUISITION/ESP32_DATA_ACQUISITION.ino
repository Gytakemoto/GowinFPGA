
#define START 0
#define READ_WRITE 1
#define ADDRESS 2
#define MSG 3
#define SEND 4
#define THRESHOLD 5
#define THRESHOLD_VALUE 6
#define SAMPLES_AFTER 7
#define SAMPLES_BEFORE 8
#define RECEIVE_MESSAGE 9
#define SAMPLE_AFTER_MAX 0x3FFFFF
#define MESSAGE_SIZE 16    // Tamanho da mensagem (3 bytes)

#define BUFFER_THRESHOLD 5120 // Tamanho do buffer antes de enviar
char outputBuffer[BUFFER_THRESHOLD]; // Buffer para armazenar os dados formatados
int outputIndex = 0;                 // Índice atual do buffer


HardwareSerial GwSerial(1); // define a Serial para UART1
const int GwSerialRX = 16;
const int GwSerialTX = 17;
int led = 2;
int step = 0;
int samples_after = 0;
uint8_t message[10];
bool reading = false;
bool writing = false;
bool acquisition = false;
int refresh = 0;
int messageLength = 0; // variável para armazenar o comprimento da mensagem
bool AutoSend = false;


#define RX_BUFFER_SIZE 256  // Tamanho do buffer para armazenar mensagens recebidas
char rxBuffer[RX_BUFFER_SIZE];  // Buffer para armazenar dados recebidos
int rxIndex = 0;               // Índice do próximo byte no buffer

const byte numChars = 32;
char receivedChars[numChars];
bool newData = false;

// Cada char é equivalente a 1 byte
char incomingBytes[8];

unsigned long LastTime = 0;
int byteCounter;

void setup() {
  Serial.begin(921600); // Monitor serial
  GwSerial.setRxBufferSize(65536);
  GwSerial.begin(921600, SERIAL_8N1, GwSerialRX, GwSerialTX); // Gowin Serial
  Serial.setTimeout(1000);
  pinMode(led, OUTPUT);
  Serial.println("Started!");
}

void loop() {

  switch (step) {
    case START:
      refresh = refresh + 1;
      if (refresh == 1) {
        Serial.println();
        Serial.println("[User] [A0] Begin UART communication? (y/n)");
      }
      else if (refresh > 1 && refresh < 8) {
        Serial.print(".");
        delay(500);
      }
      else{
        refresh = 0;
        delay(2000);
      }

        //Receber comandos pelo monitor serial
        recvWithEndMarker();

        if (newData == true) {
          newData = false;
          Serial.println(receivedChars);

          if(strcmp(receivedChars,"y") == 0  || strcmp(receivedChars,"Y") == 0){
            step = READ_WRITE;
            Serial.println("[Auto] User selected to begin communication");
            refresh = 0;
          }
          else if(strcmp(receivedChars,"n") == 0  || strcmp(receivedChars,"N") == 0){
            Serial.println("[Auto] User selected NOT to begin communication");
          }
          else{
            Serial.println("\n[Auto] Invalid input, please type a valid entry");
          }
        }       
      break;
    case READ_WRITE:
      refresh = refresh + 1;
      if (refresh == 1) {
        Serial.println();
        Serial.println("[User] [A1] Perform read, write or acquisition operation? (w/r/a)");
      }
      else if (refresh > 1 && refresh < 8) {
        Serial.print(".");
        delay(500);
      }
      else{
        refresh = 0;
        delay(2000);
      }

      //Receber comandos pelo monitor serial
      recvWithEndMarker();

      if (newData == true) {
        newData = false;
        if (strcmp(receivedChars,"w") == 0  || strcmp(receivedChars,"W") == 0) {
          writing = true;
          reading = false;
          message[0] = 0x57; // Letra "W"
          step = ADDRESS;
          Serial.println();
          Serial.println("[Auto] User selected a write operation");
          refresh = 0;
        }
        else if (strcmp(receivedChars,"r") == 0  || strcmp(receivedChars,"R") == 0) {
          reading = true;
          writing = false;
          message[0] = 0x52; // Letra "R"
          step = ADDRESS;
          Serial.println();
          Serial.println("[Auto] User selected a read operation");
          refresh = 0;
        }
        else if (strcmp(receivedChars,"a") == 0  || strcmp(receivedChars,"A") == 0){
          acquisition = true;
          message[0] = 0x41; //Letra "A"
          step = THRESHOLD;
          Serial.println();
          Serial.println("[Auto] User selected an acquisition operation");
          refresh = 0;
        }
        else{
          Serial.println("\n[Auto] Invalid input, please type a valid entry");
        }
      }
      break;
    case ADDRESS:
      refresh = refresh + 1;
      if (refresh == 1) {
        Serial.println();
        Serial.println("[User] Enter the 22-bit address in HEX format (i.e 001234)");
      }
      else if (refresh > 1 && refresh < 8) {
        Serial.print(".");
        delay(500);
      }
      else{
        refresh = 0;
        delay(2000);
      }

      //Receber comandos pelo monitor serial
      recvWithEndMarker();

      if (newData == true) {
        newData = false;
        // Converter o endereço digitado de string para número hexadecimal
        long address = strtol(receivedChars, NULL, 16);

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
      break;
    case MSG:
      refresh = refresh + 1;
      if (refresh == 1) {
        Serial.println();
        Serial.println("[User] Enter the 16-bit message in HEX format (i.e 1234)");
      }
      else if (refresh > 1 && refresh < 8) {
        Serial.print(".");
        delay(500);
      }
      else{
        refresh = 0;
        delay(2000);
      }

      //Receber comandos pelo monitor serial
      recvWithEndMarker();

      if (newData == true) {
        newData = false;
        // Converter a mensagem de string para número hexadecimal
        long msg = strtol(receivedChars, NULL, 16);

        // Atribuir os 2 bytes da mensagem ao message[]
        message[4] = (msg >> 8) & 0xFF;
        message[5] = (msg) & 0xFF;

        Serial.println();
        Serial.print("A mensagem digitada foi: ");
        Serial.println(msg, HEX);
        step = SEND;
      }
      break;
    case THRESHOLD:
      refresh = refresh + 1;
      if (refresh == 1) {
        Serial.println();
        Serial.println("[User] [A2] Enter the start-up method: t (Threshold)/ b (Button)");
      }
      else if (refresh > 1 && refresh < 8) {
        Serial.print(".");
        delay(500);
      }
      else{
        refresh = 0;
        delay(2000);
      }

      //Receber comandos pelo monitor serial
      recvWithEndMarker();

      if (newData == true) {
        newData = false;
        if (strcmp(receivedChars,"t") == 0  || strcmp(receivedChars,"T") == 0) {
          message[1] = 0x54; // Letra "T"
          step = THRESHOLD_VALUE;
          Serial.println();
          Serial.println("[Auto] User selected threshold method");
          refresh = 0;
        }
        else if (strcmp(receivedChars,"b") == 0  || strcmp(receivedChars,"B") == 0) {
          message[1] = 0x42; // Letra "B"
          step = THRESHOLD_VALUE;
          Serial.println();
          Serial.println("[Auto] User selected button method");
          refresh = 0;
        }
        else{
          Serial.println("\n[Auto] Invalid input, please type a valid entry");
        }
      }
    break;
    case THRESHOLD_VALUE:
      refresh = refresh + 1;

      // Só exibe instruções se o trigger for por threshold (0x54 = 'T')
      if (message[1] == 0x54) {
        if (refresh == 1) {
          Serial.println();
          Serial.println("[User] [A3] Enter the threshold voltage in the range -5 to 5 V (e.g., 1.23)");
        }
        else if (refresh > 1 && refresh < 8) {
          Serial.print(".");
          delay(500);
        }
        else {
          refresh = 0;
          delay(2000);
        }
      }
      else if (message[1] == 0x42) { // Trigger por Botão ('B')
        int fake_threshold = 1 << 12; // Valor fictício fora da faixa de ADC
        message[2] = fake_threshold >> 8;
        message[3] = fake_threshold;
        Serial.println("\n[Auto] Button triggered successfully!");
        step = SAMPLES_AFTER;
        refresh = 0;
        break;
      }
       
      recvWithEndMarker();

      if (newData == true) {
        newData = false;

        if (message[1] == 0x54) { // Trigger por Threshold ('T')
          float v_threshold = atof(receivedChars);

          if (v_threshold < -5.0 || v_threshold > 5.0) {
            Serial.println("\n[Auto] Invalid value. Please enter a number between -5.0 and 5.0");
            step = THRESHOLD_VALUE;
            refresh = 0;
            break;
          }

          int adc_threshold = round(((5.0 - v_threshold) / 10.0) * 4095.0);
          message[2] = adc_threshold >> 8;
          message[3] = adc_threshold;

          Serial.println();
          Serial.print("[Auto] Threshold set to ");
          Serial.print(v_threshold, 3);
          Serial.print(" V (ADC: ");
          Serial.print(adc_threshold);
          Serial.println(")");
        }
        step = SAMPLES_AFTER;
        refresh = 0;
      }
      break;
    case SAMPLES_AFTER:
      refresh = refresh + 1;
      if (refresh == 1) {
        Serial.println();
        Serial.println("[User] [A4] Enter the number of samples to be collected AFTER threshold detection (maximum = 4.194.303) \n Enter 'max' to automatically insert 4,194,303 samples");
        //Serial.println("[User] Enter 'max' to automatically insert 4,194,303 samples");
      }
      else if (refresh > 1 && refresh < 8) {
        Serial.print(".");
        delay(500);
      }
      else{
        refresh = 0;
        delay(2000);
      }

      //Receber comandos pelo monitor serial
      recvWithEndMarker();
      
      // Verifica se há dados disponíveis no buffer serial
      if (newData == true) {
        newData = false;
        Serial.println();
        char *endpoint;
        if (strcmp(receivedChars,"max") == 0  || strcmp(receivedChars,"MAX") == 0 || strcmp(receivedChars,"Max") == 0) {
          samples_after = SAMPLE_AFTER_MAX; // Valor máximo de 4,194,303
        }
        else {
          
          samples_after = strtol(receivedChars, &endpoint, 10); // Converte entrada para int

          if(endpoint == receivedChars || *endpoint != '\0'){
            Serial.println("[Auto] Invalid value. Please, insert only numeric values or 'max'");
            step = SAMPLES_AFTER;
            refresh = 0;
            break;
          }
        }

        if (samples_after >= 0 && samples_after <= SAMPLE_AFTER_MAX) {
          // Adiciona ao array message
          message[4] = (samples_after >> 16) & 0xFF; // Byte mais significativo
          message[5] = (samples_after >> 8) & 0xFF;  // Byte intermediário
          message[6] = samples_after & 0xFF;         // Byte menos significativo

          Serial.println();
          Serial.print("[Auto] 'Samples after' defined as: ");
          Serial.println(samples_after);
          step = SAMPLES_BEFORE; // Próximo passo
          refresh = 0;
        } else {
          Serial.println("[Auto] Invalid number of samples! Please enter a value between 0 and 4.194.303");
          step = SAMPLES_AFTER;
          refresh = 0;
        }
      }
      break;
    case SAMPLES_BEFORE:
      refresh = refresh + 1;
      if (refresh == 1) {
        Serial.println();
        String message = "[User] [A5] Enter the number of samples to be collected BEFORE threshold detection (maximum = 4,194,303 - samples after: ";
        message += (SAMPLE_AFTER_MAX - samples_after);
        message += ") \nEnter 'max' to automatically insert the maximum allowed samples";
        Serial.println(message);

      }
      else if (refresh > 1 && refresh < 8) {
        Serial.print(".");
        delay(500);
      }
      else{
        refresh = 0;
        delay(2000);
      }
      
      //Receber comandos pelo monitor serial
      recvWithEndMarker();

      //Serial monitor detectou um enter através de "\0"
      if (newData == true) {
        Serial.println();
        newData = false;
        long samples_before;
        char *endpoint;

        // Calcular o valor máximo permitido dinamicamente
        int samples_before_max = SAMPLE_AFTER_MAX - samples_after;

        // Verifica se a entrada é "max" ou um número válido
        if (strcmp(receivedChars,"max") == 0  || strcmp(receivedChars,"MAX") == 0 || strcmp(receivedChars,"Max") == 0) {
          samples_before = samples_before_max; // Valor máximo permitido
        }
        else {
      
          samples_before = strtol(receivedChars, &endpoint, 10); // Converte entrada para int

          if(endpoint == receivedChars || *endpoint != '\0'){
            Serial.println("[Auto] Invalid value. Please, insert only digits or 'max'");
            step = SAMPLES_BEFORE;
            refresh = 0;
            break;
          }
        }

        if (samples_before >= 0 && samples_before <= samples_before_max) {
          // Adiciona ao array message
          message[7] = (samples_before >> 16) & 0xFF; // Byte mais significativo
          message[8] = (samples_before >> 8) & 0xFF;  // Byte intermediário
          message[9] = samples_before & 0xFF;         // Byte menos significativo

          Serial.println();
          Serial.print("[Auto] 'Samples before' defined as: ");
          Serial.println(samples_before);
          step = SEND; // Avança para a etapa de envio
        } 
        else {
          Serial.println("[Auto] Invalid number of samples! Please enter a value between 0 and ");
          Serial.println(samples_before_max);
          step = SAMPLES_BEFORE;
          refresh = 0;
        }
      }
      break;
    case SEND:
    {
      if (writing) {
        messageLength = 6;
      }
      else if (reading) {
        messageLength = 4;
      }
      else if(acquisition) {
        messageLength = 10;
      }

      // Enviar a mensagem via UART
      int sentBytes = GwSerial.write(message, messageLength);

      // Verificar se a quantidade de bytes enviados corresponde ao esperado
      if (sentBytes == messageLength) {
        Serial.println();
        Serial.println("[Auto] Message sent successfully!");
      }
      else {
        Serial.println("[Auto] Sending message...");
      }
      reading = false;
      writing = false;
      LastTime = 0;
      AutoSend = true;
      step = RECEIVE_MESSAGE; // Voltar ao início após o envio
    break;
    }
    case RECEIVE_MESSAGE:
      static int bytesRead = 0; // Variável estática para persistir o valor entre chamadas
      char tempBuffer[2048];

      
      if(AutoSend){
        delay(random(1000, 1500));
        //delay(100);
        GwSerial.write("S", 1);
        AutoSend = false;
      }
      

      if (GwSerial.available() > 0) {
          LastTime = millis();

          // Leia vários bytes disponíveis no buffer serial
          bytesRead = GwSerial.readBytes(tempBuffer, sizeof(tempBuffer));

          // Envie os dados lidos imediatamente
          if (bytesRead >= 2048) {
              Serial.write(tempBuffer, bytesRead);
              bytesRead = 0;
          }
      }

      // Verifique se houve inatividade e finalize a transmissão
      if (millis() - LastTime > 1000 && LastTime != 0) {
          if (bytesRead > 0) {
              Serial.write(tempBuffer, bytesRead);
          }

          delay(3000);

          // Finalize o processo
          Serial.print("\n[Auto] Transmission ended\n");
          step = START;
      }
      break;
  }
}

void recvWithEndMarker() {
  static byte ndx = 0;
  char endMarker = '\n';
  char rc;
  
  while (Serial.available() > 0 && newData == false) {
    rc = Serial.read();

    if (rc != endMarker) {
      receivedChars[ndx] = rc;
      ndx++;
      if (ndx >= numChars) {
        ndx = numChars - 1;
      }
    }
    else {
      receivedChars[ndx] = '\0'; // terminate the string
      ndx = 0;
      newData = true;
    }
  }
}
