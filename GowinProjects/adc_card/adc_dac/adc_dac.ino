#include <driver/ledc.h>

const int ADC_CLK_Pin = 21; // Pino para gerar o clock do ADC
const int DAC_OUT_Pin = 26; // Pino de saída do DAC
const int Pot_Pin = 15;     // Pino do potenciômetro
//const int OTR_Pin = 12;
const int ADC_CLK_Pin_IN = 23;

//int bitValue;

// Array para os pinos de dados do ADC
const int ADC_Data_Pins[] = {34, 19, 35, 18, 32, 5, 33, 17, 27, 16, 14, 4};

void setup() {
  // Configuração do pino do clock do ADC
  pinMode(ADC_CLK_Pin, OUTPUT);

  // Configuração do DAC e do potenciômetro
  pinMode(Pot_Pin, INPUT);

  pinMode(ADC_CLK_Pin_IN, INPUT);

  // Configuração dos pinos de dados do ADC como entrada
  for (int i = 0; i < 12; i++) {
    pinMode(ADC_Data_Pins[i], INPUT);
  }
  ledcAttach(ADC_CLK_Pin, 1000, 8);  // Canal 0 ligado ao pino ADC_CLK_Pin)
  
  Serial.begin(115200); // Inicializa a comunicação serial com baud rate de 115200

}

void loop() {

  //digitalWrite(ADC_CLK_Pin, clkState);
  ledcWriteTone(ADC_CLK_Pin, 1000);

  // Ler a tensão do potenciômetro (0-4095 para ADC de 12 bits)
  int potValue = analogRead(Pot_Pin);

  // Enviar a tensão lida para o DAC
  dacWrite(DAC_OUT_Pin, potValue >> 4); // Ajuste para escala de 8 bits (0-255)

  /*
  // Detecta flanco de descida
  if (digitalRead(ADC_CLK_Pin) == 1) {
    //int adcData = 0;

    //int OTRValue = digitalRead(OTR_Pin);

    // Mostrar dados no monitor serial
    Serial.printf("Potenciômetro: %d, ADC:", potValue);
    //Serial.printf("\t OTR: %d \t", OTRValue);

    for (int i = 11; i >= 0; i--) {
      int bitValue = digitalRead(ADC_Data_Pins[i]);
      //adcData |= (bitValue << i);
      Serial.print(bitValue);
    }
    Serial.println();
  }
  delayMicroseconds(500); // Meio período do clock (1 kHz = 1000 µs por ciclo)
  clkState = !clkState;
  */
  
  if(digitalRead(ADC_CLK_Pin_IN) == 1){
    for (int i = 11; i >= 0; i--) {
    int bitValue = digitalRead(ADC_Data_Pins[i]);
    //adcData |= (bitValue << i); // Construir o valor de 12 bits do ADC
    Serial.print(bitValue);
    }
    Serial.println();
  }
  //delay(100); // Ajuste para controle de leitura (10 ms no exemplo)
}