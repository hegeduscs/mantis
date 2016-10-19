//
// This file is part of the GNU ARM Eclipse distribution.
// Copyright (c) 2014 Liviu Ionescu.
//

// ----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include "diag/Trace.h"

#include "init.h"
#include "BlinkLed.h"
#include "utils.h"

#include "stm32f407xx.h"
#include "TM_lib/tm_stm32_delay.h"
#include "TM_lib/tm_stm32_fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "TM_lib/tm_stm32_mpu6050.h"
#include "TM_lib/tm_stm32_adc.h"

// ----- main() ---------------------------------------------------------------

// Sample pragmas to cope with warnings. Please note the related line at
// the end of this function, used to pop the compiler diagnostics status.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-declarations"
#pragma GCC diagnostic ignored "-Wreturn-type"

/* Fatfs structure */
FATFS FS;
FIL fil;
FRESULT fres;


/* Buffer variable */
char buffer[100];

// RTC buffers
TM_RTC_t datetime;

//readout buffers
TM_MPU6050_t mpu_buffer;

//Button object
TM_BUTTON_t* userButton;

//status variables
char blinkStatus;
char initStatus;
char logRequired;
char stopExecution;

//measurement variables
TM_MPU6050_t max_value;


int main(int argc, char* argv[]) {
	/* Init system clock for maximum system speed */
	TM_RCC_InitSystem();

	/* Init HAL layer */
	HAL_Init();
	initSystem();

	//if something happened during init, stop execution
	if (initStatus) {
		//TODO: add exception handling for init section; e.g. try to mount SD card until sucessful
		trace_printf("Init error code:%u\n",initStatus);
		TM_RTC_SetDateTimeString("05.10.16.6;00:01:00");
		//stops blinking
		TM_RTC_Interrupts(TM_RTC_Int_Disable);
		blink_led_on();
		while(1) {}
	};

	//init global variables
	stopExecution=0;
    logRequired=0;
    max_value.Accelerometer_X=0;
    max_value.Gyroscope_X=0;

	  while(!stopExecution){
		  if (logRequired) {
			  TM_RTC_GetDateTime(&datetime,TM_RTC_Format_BIN);
			  //writint into file
			  writeLogEntry(&fil, datetime, max_value, 0);
			  //TODO: clear meas buffers
			  logRequired=0;
		  }

		  //do measurements, store in temp variables
		  //TODO: MPU MAX_HOLD
         //TODO: vibration sensor
 		uint16_t result = TM_ADC_Read(ADC1, TM_ADC_Channel_1);
 		trace_printf("%u\n",result);
 		TM_BUTTON_Update();
	  }

	  	trace_printf("BYE\n");
  		f_close(&fil);
  		f_mount(NULL, "SD:", 1);
}

void TM_RTC_WakeupHandler(void) {
	//toggle LED-s, if init didn't fail
	if (!stopExecution) {
		if (blinkStatus) {
			//was On
			blink_led_off();
			blinkStatus=0;

		} else {
			//was Off
			blink_led_on();
			blinkStatus=1;
		}
	}

	logRequired=1;
}


#pragma GCC diagnostic pop

// ----------------------------------------------------------------------------
