#include "utils.h"
#include "TM_lib/tm_stm32_usart.h"

static char buffer[200];

void writeLogEntry (FIL* fil, TM_RTC_t datetime, MPUBUFFER *IMU_data, uint16_t vibration_data) {
	//format: TIMESTAMP;VIBRATION_AVG;MAX_ACC;MAX_GYRO
	//specified in init.c: initSD();


	snprintf(buffer,200,"%u:%u:%u;%d;%d;%d",datetime.Hours,datetime.Minutes,datetime.Seconds, IMU_data->accel[0], IMU_data->accel[1], (int)vibration_data);
	//TM_USART_Puts(USART3, buffer);
	f_printf(fil,"%s\n",buffer);

	//needs to actually write to SD card
	f_sync(fil);
}



