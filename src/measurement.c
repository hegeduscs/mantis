#include "measurement.h"
#include "utils.h"



void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
	if (htim->Instance==TIM2) { //30
		toggleLED(LED_ERROR);
		trace_printf("TODO: do temp,dust meas; toggle operational LED\n");
	}
	if (htim->Instance==TIM3) {
		trace_printf("TODO:logging\n");
	}
}
