#include "measurement.h"
#include "utils.h"


void writeLogEntry (FIL* fil) {
	//format: TIMESTAMP;VIBRATION_AVG;MAX_ACC;MAX_GYRO
	//specified in init.c: initSD();


	//snprintf(buffer,200,"%u:%u:%u;%d;%d;%d",datetime.Hours,datetime.Minutes,datetime.Seconds, IMU_data->accel[0], IMU_data->accel[1], (int)vibration_data);
	//TM_USART_Puts(USART3, buffer);
	//f_printf(fil,"%s\n",buffer);

	//needs to actually write to SD card
	f_sync(fil);
}


void HAL_TIM_PeriodElapsedCallback(TIM_HandleTypeDef *htim) {
	if (htim->Instance==TIM2) { //30
		toggleLED(LED_ERROR);
		trace_printf("TODO: do temp,dust meas; toggle operational LED\n");
	}
	if (htim->Instance==TIM3) {
		trace_printf("TODO:logging\n");
	}
}
