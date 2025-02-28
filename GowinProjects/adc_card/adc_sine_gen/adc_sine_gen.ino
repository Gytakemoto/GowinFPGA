#include <driver/dac.h>
//#include <driver/dac_common.h>

const int DAC_OUT_Pin = 26; // Pino de saída do DAC (GPIO 26)
const int Pot_Pin = 15;     // Pino do potenciômetro

// Parâmetros da onda
const float amplitude = 1.5 / 2.0; // Amplitude da onda (1.5Vpp / 2 = 0.75V de pico)
const float offset = 0.75;         // Offset para deslocar a onda para 0V a 1.5V
const float vref = 3.3;            // Tensão de referência do DAC

void setup() {
  // Configuração do potenciômetro como entrada
  pinMode(Pot_Pin, INPUT);

  // Inicializa o DAC cosine no pino 26 (DAC1)
  dac_cw_config_t cw_config = {
    .en_ch = DAC_CHANNEL_1,          // Usar DAC1 (GPIO 25) ou DAC2 (GPIO 26)
    .scale = DAC_CW_SCALE_1,         // Escala de amplitude (1x)
    .phase = DAC_CW_PHASE_0,         // Fase inicial (0 graus)
    .freq = 1000,                    // Frequência inicial (1kHz)
    .offset = 0                      // Offset inicial (0V)
  };
  dac_cw_generator_config(&cw_config);
  dac_output_enable(DAC_CHANNEL_2);  // Habilitar saída do DAC1
  dac_cw_generator_enable();         // Habilitar o gerador de onda cosseno
}

void loop() {
  // Ler a tensão do potenciômetro (0-4095 para ADC de 12 bits)
  int potValue = analogRead(Pot_Pin);

  // Mapear o valor do potenciômetro para a frequência desejada (por exemplo, 1Hz a 1000Hz)
  //uint32_t frequency = map(potValue, 0, 4095, 1, 10000);
  uint32_t frequency = 1000000;

  // Configurar a frequência do gerador de onda cosseno
  dac_cw_config_t cw_config = {
    .en_ch = DAC_CHANNEL_2,
    .scale = DAC_CW_SCALE_1,
    .phase = DAC_CW_PHASE_0,
    .freq = frequency,               // Nova frequência
    .offset = 0
  };
  dac_cw_generator_config(&cw_config);

  // Pequeno delay para evitar leituras muito rápidas do potenciômetro
  delay(10);
}