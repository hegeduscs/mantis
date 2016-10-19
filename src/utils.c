#include "utils.h"

void writeLogEntry (FIL* fil, TM_RTC_t datetime, TM_MPU6050_t IMU_data, uint16_t vibration_data) {
	//format: TIMESTAMP;VIBRATION_AVG;MAX_ACC;MAX_GYRO
	//specified in init.c: initSD();

	char buffer[200];
	snprintf(buffer,200,"%u:%u:%u;%f;%f",datetime.Hours,datetime.Minutes,datetime.Seconds,IMU_data.Accelerometer_X,IMU_data.Gyroscope_X);
	f_printf(fil,"%s\n",buffer);

	//needs to actually write to SD card
	f_sync(fil);
}



