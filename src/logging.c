#include "logging.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "fatfs.h"
#include "init.h"

extern currentFileName[];

void openLogFile() {
	//getting timestamp for file
	TM_RTC_t timeBuffer;
	TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);

	sprintf(currentFileName,"%d-%d-%d.txt\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day);

	 if (f_open(&log1, currentFileName, FA_OPEN_EXISTING |FA_READ | FA_WRITE) == FR_OK) {
			//try to open existing file
		  	 //however we need to append to it!
		  	f_lseek(&log1, f_size(&log1));
			f_sync(&log1);
		  } else
		  	 //has to create file
		  	if ( initStatus!=ERROR_RTC_NOT_SET) {
		  		if (f_open(&log1, currentFileName, FA_CREATE_ALWAYS|FA_READ | FA_WRITE) == FR_OK) {
		  				//add header
		  				f_printf(&log1,"File creation at: %u-%u-%u %u:%u:%u, ID:%u\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day,timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds,isValidConfig());
		  				f_puts(MANTIS_MEAS_HEADER,&log1);
		  				f_sync(&log1);
		  		}
			 } else { //ERROR_RTC_NOT_SET
				 f_open(&log1, "default.txt", FA_CREATE_ALWAYS|FA_READ | FA_WRITE);
			 }
}

void openDebugFile() {
	 if (f_open(&log_debug, "debug.txt", FA_OPEN_EXISTING |FA_READ | FA_WRITE) == FR_OK) {
		 //try to open existing file
		 //however we need to append to it!
		 f_lseek(&log_debug, f_size(&log1));
		 f_sync(&log_debug);
	 } else {
		 TM_RTC_t timeBuffer;
		 TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);

		 if (f_open(&log_debug, "debug.txt", FA_CREATE_ALWAYS|FA_READ | FA_WRITE) == FR_OK) {
			 //add header
			 f_printf(&log1,"File creation at: %u-%u-%u %u:%u:%u\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day,timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds);
			 f_sync(&log_debug);
		 } else {
			 initStatus=ERROR_FILE_OPEN;
		 }
	 }
}

void checkLogging() {
	//check if enough space is left on card for the next day
	//if not, then need to restart
	if (checkSD()!=INIT_OK) HAL_NVIC_SystemReset();

	//getting current date and time
	TM_RTC_t timeBuffer;
	TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);

	//creating actual fileName
	char rightName[100];
	sprintf(rightName,"%d-%d-%d.txt\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day);

	//if they are not equal, need to create new file
	if (initStatus!=ERROR_RTC_NOT_SET&&strcmp(rightName,currentFileName)) {
		//close file and reboot
		f_close(&log1);
		f_close(&log_debug);
		f_mount(0, "", 1);
		HAL_NVIC_SystemReset();
	}
}


int checkSD() {
	FATFS *fs;
	DWORD fre_clust;
	FRESULT res;

	/* Get volume information and free clusters of drive */
	if ((res = f_getfree("SD1", &fre_clust, &fs)) != FR_OK) {
		return 0;
	}
	int total = (fs->n_fatent - 2) * fs->csize * 0.5;
	int free = fre_clust * fs->csize * 0.5;

	//trace_printf("All storage:%d KB, free:%d KB\n",total,free);

	if (free > (MANTIS_MEAS_ENTRY_SIZE*3600*8)) {
		return INIT_OK;
	} else
		return ERROR_FILE_OPEN;
}

char binFileName[100];
void openBinaryFile()
{
	//Get data from RTC
	TM_RTC_t timeBuffer;
	TM_RTC_GetDateTime(&timeBuffer, TM_RTC_Format_BIN);
	sprintf(binFileName,"%d-%d-%d.dat\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day);

	//Open file or create one if it doesn't exist
	if(f_open(&log_bin, binFileName, FA_READ | FA_WRITE | FA_OPEN_EXISTING) == FR_OK)
	{
		f_lseek(&log_bin, f_size(&log_bin));
		f_sync(&log_bin);
	}
	else
	{
		if(initStatus != ERROR_RTC_NOT_SET)
		{
			if (f_open(&log_bin, binFileName, FA_READ | FA_WRITE | FA_CREATE_ALWAYS) == FR_OK)
			{
				f_sync(&log_bin);
			}
		}
		else
		{
			f_open(&log_bin, "def_RTC.dat", FA_READ | FA_WRITE | FA_CREATE_ALWAYS);
		}
	}
}

void binary_log(MPU_measurement theBuff)
{
	short buffer[6];
	TM_RTC_t timeBuffer;
	uint8_t outTimeBuff[6];
	UINT *error_indicator;

	for(int i = 0; i<3; i++)
	{
		buffer[i] = theBuff.accel[i];
		buffer[i+3] = theBuff.gyro[i];
	}

	TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);
	outTimeBuff[0] = timeBuffer.Year;
	outTimeBuff[1] = timeBuffer.Month;
	outTimeBuff[2] = timeBuffer.Day;
	outTimeBuff[3] = timeBuffer.Hours;
	outTimeBuff[4] = timeBuffer.Minutes;
	outTimeBuff[5] = timeBuffer.Seconds;

	//Writing timestamp
	f_write(&log_bin, outTimeBuff, sizeof(outTimeBuff), error_indicator);
	if(&error_indicator < sizeof(outTimeBuff))
	{
		trace_printf("SD is full!");
	}

	//Writing data
	f_write(&log_bin, &buffer, sizeof(buffer), error_indicator);
	if(&error_indicator < sizeof(outTimeBuff))
		{
			trace_printf("SD is full!");
		}
	f_sync(&log_bin);
}

