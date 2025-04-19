#include <driver/dac.h>

const int DAC_OUT_Pin = 26; // Pino de saída do DAC (GPIO 26)
const int Pot_Pin = 15;     // Pino do potenciômetro

void setup() {
  // Habilitar a saída do DAC
  dac_output_enable(DAC_CHANNEL_1);

  // Configurar o gerador de onda cosseno
  dac_cw_config_t cw_config = {
    .en_ch = DAC_CHANNEL_1,   // Canal do DAC
    .scale = DAC_CW_SCALE_4,  // Ajuste de amplitude (testar DAC_CW_SCALE_1, _2, _4)
    .phase = DAC_CW_PHASE_0,  // Fase inicial
    .freq = 1000,             // Frequência da onda
    .offset = 0             // Offset central (meio da faixa 0-255)
  };

  // Configurar e iniciar a geração da onda
  dac_cw_generator_config(&cw_config);
  dac_cw_generator_enable();
}

void loop() {
  delay(100); // Pequeno atraso para evitar instabilidade
}
