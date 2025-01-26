#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "freertos/FreeRTOS.h"


#include "soc/rtc_io_reg.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/sens_reg.h"
#include "soc/rtc.h"
#include "esp_adc_cal.h"
#include "driver/dac.h"
#include "driver/adc.h"


void setup_adc(esp_adc_cal_characteristics_t *adc_chars){
  //Set ADC configuration
  esp_adc_cal_value_t val_type = esp_adc_cal_characterize(ADC_UNIT_1, ADC_ATTEN_DB_12, ADC_WIDTH_BIT_12, 0, adc_chars);

  //Set ADC width
  adc1_config_width(ADC_WIDTH_BIT_12);

  //Set ADC attenuation
  adc1_config_channel_atten(ADC_CHANNEL_0, ADC_ATTEN_DB_12);

}

int read_adc(adc_channel_t channel, esp_adc_cal_characteristics_t *adc_chars){
  // Read raw data
  uint32_t reading = adc1_get_raw(channel);

  // Convert raw data to voltage in mV
  uint32_t voltage = esp_adc_cal_raw_to_voltage(reading, adc_chars);

  printf("Raw value: %ld\n Calculated voltage: %ld \n", reading, voltage);

  return reading;
}

void set_dac(dac_channel_t channel, uint8_t raw_voltage){
  // Set DAC configuration
  dac_output_enable(channel);
  dac_output_voltage(channel, raw_voltage);
}


void app_main(void)
{
  esp_adc_cal_characteristics_t *adc_chars = malloc(sizeof(esp_adc_cal_characteristics_t));
  setup_adc(adc_chars);

  while(1){
    //Read ADC Pin (GPIO-36)
    int raw_read = read_adc(ADC_CHANNEL_0, adc_chars) >> 4;    // Excluding 4 LSB bits to fit in 8-bit DAC
    printf("8-bit raw reading: %d\n", raw_read);
    dac_output_voltage(DAC_CHAN_1, raw_read);
  }

  free(adc_chars);

}
