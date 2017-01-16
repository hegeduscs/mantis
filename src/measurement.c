#include "measurement.h"
#include "utils.h"
#include "fatfs.h"

extern FIL log1;

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
	if (htim->Instance==TIM2) { //30
		//toggleLED(LED_ERROR);
		//trace_printf("Temperature logged.\n");
		toggleLED(LED_GREEN);
		HIH_readout hbuf;
		HIH_read(&hbuf);

		char buffer[200];
		TM_RTC_t timeBuffer;
		TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);

		snprintf(buffer,200,"%u:%u:%u;%lf;%lf",timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds,hbuf.temperature,hbuf.humidity);
		f_printf(&log1,"%s\n",buffer);
		f_sync(&log1);
	}
	if (htim->Instance==TIM3) {
		//trace_printf("TODO:logging\n");
	}
	if (htim->Instance==TIM4) {
		//trace_printf("SD card is low or RTC not set\n");
		BlinkErrors();
	}
}

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin) {
	//trace_printf("EXTI CALLED:%d\n",GPIO_Pin);
}

