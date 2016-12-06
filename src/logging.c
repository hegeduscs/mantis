#include "logging.h"

void openFiles() {
	//getting timestamp for file
	TM_RTC_t timeBuffer;
	TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);



	char fileName[30];
	sprintf(fileName,"%d-%d-%d.txt\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day);

	 if (f_open(&log1, fileName, FA_OPEN_EXISTING |FA_READ | FA_WRITE) == FR_OK) {
			//try to open existing file
		  	 //however we need to append to it!
		  	f_lseek(&log1, f_size(&log1));
			f_sync(&log1);
		  } else
		  	 //has to create file
		  	if ( initStatus!=ERROR_RTC_NOT_SET && f_open(&log1, fileName, FA_CREATE_ALWAYS|FA_READ | FA_WRITE) == FR_OK) {
		  		//add header

			  	f_printf(&log1,"File creation at: %u-%u-%u %u:%u:%u\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day,timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds);
			  	//TODO: custom header
			  	f_puts(MANTIS_MEAS_HEADER,&log1);
			  	f_sync(&log1);
			 } else {
				 if (initStatus!=ERROR_RTC_NOT_SET) initStatus=ERROR_FILE_OPEN; //can't open/create file
			 }
}

void createFile(int type) {

}

void writeLogEntry (FIL* fil, int type) {
	//format: TIMESTAMP;VIBRATION_AVG;MAX_ACC;MAX_GYRO
	//specified in init.c: initSD();


	//snprintf(buffer,200,"%u:%u:%u;%d;%d;%d",datetime.Hours,datetime.Minutes,datetime.Seconds, IMU_data->accel[0], IMU_data->accel[1], (int)vibration_data);
	//TM_USART_Puts(USART3, buffer);
	//f_printf(fil,"%s\n",buffer);

	//needs to actually write to SD card
	f_sync(fil);
}
