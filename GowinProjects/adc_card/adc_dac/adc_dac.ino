#include "driver/ledc.h"

const int ADC_CLK_Pin = 23; // Pino para gerar o clock do ADC
const int DAC_OUT_Pin = 26; // Pino de saída do DAC
const int Pot_Pin = 15;     // Pino do potenciômetro
const int OTR_Pin = 13;

// Array para os pinos de dados do ADC
const int ADC_Data_Pins[] = {34, 22, 35, 1, 32, 3, 33, 21, 27, 19, 14, 18};

void setup() {
  // Configuração do pino do clock do ADC
  pinMode(ADC_CLK_Pin, OUTPUT);

  // Configuração do DAC e do potenciômetro
  pinMode(Pot_Pin, INPUT);

  // Configuração dos pinos de dados do ADC como entrada
  for (int i = 0; i < 12; i++) {
    pinMode(ADC_Data_Pins[i], INPUT);
  }
  ledcAttach(ADC_CLK_Pin, 1000, 8);  // Canal 0 ligado ao pino ADC_CLK_Pin)
  

}

void loop() {
  ledcWriteTone(ADC_CLK_Pin, 1000);

  // Ler a tensão do potenciômetro (0-4095 para ADC de 12 bits)
  int potValue = analogRead(Pot_Pin);

  // Enviar a tensão lida para o DAC
  dacWrite(DAC_OUT_Pin, potValue >> 4); // Ajuste para escala de 8 bits (0-255)

  // Leitura das saídas do ADC
  int adcData = 0;
  for (int i = 0; i < 12; i++) {
    int bitValue = digitalRead(ADC_Data_Pins[i]);
    adcData |= (bitValue << i); // Construir o valor de 12 bits do ADC
  }

  // Mostrar dados no monitor serial
  Serial.printf("Potenciômetro: %d, ADC: %d\n", potValue, adcData);

  delay(10); // Ajuste para controle de leitura (10 ms no exemplo)
}
