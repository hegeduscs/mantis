#ifndef MEAS_H
#define MEAS_H

#include "stm32f4xx.h"
#include "stm32f4xx_hal.h"
#include "diag/Trace.h"
#include "fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"

void writeLogEntry (FIL*);
void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim);

#endif
