#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "freertos/FreeRTOS.h"


#include "soc/rtc_io_reg.h"
#include "soc/rtc_cntl_reg.h"
#include "soc/sens_reg.h"
#include "soc/rtc.h"

void dac_enable(dac_channel_t channel){

  SET_PERI_REG_MASK()

}

void app_main(void)
{
  dac_enable(DAC_CHAN_1);
}
