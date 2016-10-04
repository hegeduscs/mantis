#include "init.h"

void initSystem () {
	initStatus=0;
	blink_led_init();
	initRTC();
	initSD();
	initMPU();
	initButtons();
}

void initRTC() {
	if (!TM_RTC_Init(TM_RTC_ClockSource_External)) {
	  		//RTC was first time initialized!
		  //TODO: RTC needs sync from somewhere
		  initStatus=1;
		  TM_RTC_SetDateTimeString("04.10.16.6;00:01:00");
	  	}
	//setting up 1 second interrupt from RTC, callback is in main.c
	TM_RTC_Interrupts(TM_RTC_Int_1s);

	//writing timestamp to trace for debug
	TM_RTC_t timeBuffer;
	TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);
	trace_printf("Current time is:%u-%u-%u %u:%u:%u ",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day,timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds);
}

void initSD() {
	 if (f_mount(&FS, "SD:", 1) == FR_OK) {
		 //checking SD card space
		 TM_FATFS_Size_t CardSize;
		 TM_FATFS_GetDriveSize("SD:", &CardSize);
		 trace_printf("Total card size: %u kBytes\n", CardSize.Total);
		 trace_printf("Free card size:  %u kBytes\n", CardSize.Free);
		 if (CardSize.Free<40000) { //if space is less than 40KB, then we have a problem
			 initStatus=4;
		 }

		 //opening or creating file
		 TM_RTC_t timeBuffer;
		 TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);
		 char fileName[50];
		 sprintf(fileName,"SD:/%u-%u.txt",timeBuffer.Month,timeBuffer.Day);
		 if (f_open(&fil, fileName, FA_OPEN_EXISTING |FA_READ | FA_WRITE) == FR_OK) {
			 //try to open existing file
			 //however we need to append to it!
			 //f_close(&fil);
			 //open as append
			 //f_open(&fil,fileName,FA_OPEN_APPEND|FA_READ|FA_WRITE);
			 f_lseek(&fil, f_size(&fil));
		 } else
			 //has to create file
			 if ( f_open(&fil, fileName, FA_CREATE_ALWAYS|FA_READ | FA_WRITE) == FR_OK) {
				 //add header
				 f_printf(&fil,"System init at: %u-%u-%u %u:%u:%u\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day,timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds);
				 f_puts("TIMESTAMP;VIBRATION_AVG;MAX_ACC;MAX_GYRO\n",&fil);
				 f_sync(&fil);
			 } else {
				 initStatus=3; //can't open/create file
			 }

	 } else {
			initStatus=2; //can't mount SD card
	 }
}

void initMPU() {
	//needs to set MPU's address to 0x69!
	mpu_buffer.Address=0x69;
	if (TM_MPU6050_Init(&mpu_buffer, TM_MPU6050_Device_0, TM_MPU6050_Accelerometer_2G, TM_MPU6050_Gyroscope_250s)!=TM_MPU6050_Result_Ok) {
		initStatus=5; //can't init MPU
	} else {
		//successful init
		//TODO: need calibration or something
	}
}
void initButtons() {
	userButton = TM_BUTTON_Init(GPIOA,GPIO_Pin_0 ,0, BUTTON_Callback);
	TM_BUTTON_SetPressTime(userButton, 30, 2000);
}

static void BUTTON_Callback(TM_BUTTON_t* ButtonPtr, TM_BUTTON_PressType_t PressType) {
	/* Normal press detected */
	if (PressType == TM_BUTTON_PressType_Normal) {
		/* Set LEDS ON */
		blink_led_on();
		trace_printf("BUTTON_ON");
	} else if (PressType == TM_BUTTON_PressType_Long) {
		/* Set LEDS OFF */
		blink_led_off();
		trace_printf("BUTTON_OFF");

	}
}
