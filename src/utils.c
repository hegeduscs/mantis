#include "utils.h"

void writeLogEntry (FIL* fil, TM_RTC_t datetime, TM_MPU6050_t IMU_data, uint16_t vibration_data) {
	//format: TIMESTAMP;VIBRATION_AVG;MAX_ACC;MAX_GYRO
	char accStr[20], gyroStr[20];
	int16_t acc=IMU_data.Accelerometer_X, gyro=IMU_data.Gyroscope_X;
	sprintf(accStr,"%i",acc); sprintf(gyroStr,"%i",gyro);
	/* TODO: convert IMU data into float!
	//converting floats into strings
	  //acc
	  if (acc < 0 )       //For our integer pseudo-float print, a zero-whole won't print '-' for us...
		  sprintf(accStr,"-%u.%3u",acc/1000,abs(acc)%1000);
	  else
		  sprintf(accStr,"%u.%3u",acc/1000,abs(acc)%1000);
	  //gyro
	  if (gyro < 0)
	  		  sprintf(gyroStr,"-%u.%3u",gyro/1000,abs(gyro)%1000);
	  	  else
	  		  sprintf(gyroStr,"%u.%3u",gyro/1000,abs(gyro)%1000);
	 */
	trace_printf("%u:%u:%u;%u;%s;%s\n",datetime.Hours,datetime.Minutes,datetime.Seconds,
			  	  	  	  	  	  	 vibration_data,
									 accStr,gyroStr);
	f_printf(fil,"%u:%u:%u;%u;%s;%s\n",datetime.Hours,datetime.Minutes,datetime.Seconds,
									  vibration_data,
									  accStr,gyroStr
			);
	f_sync(fil);

}
