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


#include "stm32f407xx.h"
#include "TM_lib/tm_stm32_delay.h"
#include "TM_lib/tm_stm32_fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "TM_lib/tm_stm32_mpu6050.h"

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

//MPU stuff
TM_MPU6050_t mpu_buffer;

//status variables
char blinkStatus;
char initStatus;
char logRequired;
char stopExecution;

//measurement variables

int main(int argc, char* argv[]) {
	initSystem();
	//if something happened during init, stop execution
	if (initStatus) {
		//TODO: add exception handling for init section; e.g. try to mount SD card until sucessful
		while(1) {}
	};
	stopExecution=0;
    logRequired=0;

	  while(!stopExecution){
		  if (logRequired) {
			  //TODO: needs to write to file
			  //TODO: sanity check, whether file pointer is valid

			  logRequired=0;
		  }

		  //do measurements, store in temp variables
		  //TODO: MPU MAX_HOLD
         TM_MPU6050_ReadAll(&mpu_buffer);
         trace_printf( "1. Accelerometer X:%d- Y:%d- Z:%d Gyroscope- X:%d- Y:%d- Z:%d\n",
                             mpu_buffer.Accelerometer_X,
                             mpu_buffer.Accelerometer_Y,
                             mpu_buffer.Accelerometer_Z,
                             mpu_buffer.Gyroscope_X,
                             mpu_buffer.Gyroscope_Y,
                             mpu_buffer.Gyroscope_Z
                     );

         //TODO: vibration sensor

	  }





  		f_close(&fil);
  		f_mount(NULL, "SD:", 1);
}

void TM_RTC_WakeupHandler(void) {
	//toggle LED-s, if init failed
	if (initStatus) {
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
