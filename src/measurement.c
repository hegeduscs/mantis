#include "measurement.h"
#include "utils.h"
#include "fatfs.h"

extern FIL log1;
extern FIL log_debug;

void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
	if (htim->Instance==TIM2) { //30
		//toggleLED(LED_ERROR);
		//trace_printf("Temperature logged.\n");

		HIH_readout hbuf;
		HIH_read(&hbuf);

		int dust;
		for (int i=0;i<5;i++){
			int dust_temp=dust_meas();
			if (dust_temp>0) dust+=dust_temp;
			HAL_Delay(10);
		}
		dust=(int)(dust/5);

		char buffer[200];
		TM_RTC_t timeBuffer;
		TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);

		snprintf(buffer,200,"%u:%u:%u;%lf;%lf;%d",timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds,hbuf.temperature,hbuf.humidity,dust);
		f_printf(&log1,"%s\n",buffer);
		//f_sync(&log1);
	}
	if (htim->Instance==TIM3) {
		//check if need to switch log file
		checkLogging();
	}
	if (htim->Instance==TIM4) {
		//trace_printf("SD card is low or RTC not set\n");
		//blink out errors and green status LED
		toggleLED(LED_GREEN);
		BlinkErrors();

		//sync up file system
		f_sync(&log1);
		f_sync(&log_debug);


	}
}

void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin) {
	//trace_printf("EXTI CALLED:%d\n",GPIO_Pin);
}






