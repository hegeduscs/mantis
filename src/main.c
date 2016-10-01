//
// This file is part of the GNU ARM Eclipse distribution.
// Copyright (c) 2014 Liviu Ionescu.
//

// ----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include "diag/Trace.h"

#include "Timer.h"
#include "BlinkLed.h"


#include "stm32f407xx.h"
#include "TM_lib/tm_stm32_delay.h"
#include "TM_lib/tm_stm32_fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "TM_lib/tm_stm32_i2c.h"
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

/* Size structure for FATFS */
TM_FATFS_Size_t CardSize;

/* Buffer variable */
char buffer[100];

// RTC buffers
TM_RTC_t datetime;

//MPU stuff
TM_MPU6050_t MPU6050_Data0;
TM_MPU6050_t MPU6050_Data1;

int main(int argc, char* argv[]) {
  // Send a greeting to the trace device (skipped on Release).
  trace_puts("Hello ARM World!");
  // At this stage the system clock should have already been configured
  // at high speed.
  trace_printf("System clock: %u Hz\n", SystemCoreClock);
  timer_start();
  blink_led_init();
  TM_MPU6050_Result_t result;
  MPU6050_Data0.Address=0x69;
  result=TM_MPU6050_Init(&MPU6050_Data0, TM_MPU6050_Device_0, TM_MPU6050_Accelerometer_2G, TM_MPU6050_Gyroscope_250s);
  trace_printf("%u",result);
  if (result==TM_MPU6050_Result_Ok)
  {
	  while(1){
          // Display message to user
         TM_MPU6050_ReadAll(&MPU6050_Data0);
         trace_printf( "1. Accelerometer X:%d- Y:%d- Z:%d Gyroscope- X:%d- Y:%d- Z:%d\n",
                             MPU6050_Data0.Accelerometer_X,
                             MPU6050_Data0.Accelerometer_Y,
                             MPU6050_Data0.Accelerometer_Z,
                             MPU6050_Data0.Gyroscope_X,
                             MPU6050_Data0.Gyroscope_Y,
                             MPU6050_Data0.Gyroscope_Z
                     );
	  	  }
      }


  /*
  if (!TM_RTC_Init(TM_RTC_ClockSource_External)) {
  		//RTC was first time initialized
  		//Do your stuf here
  		//eg. set default time
	  TM_RTC_SetDateTimeString("01.10.16.6;13:00:00");
  	}

  if (f_mount(&FS, "SD:", 1) == FR_OK) {
	  	TM_FATFS_GetDriveSize("SD:", &CardSize);
	  	trace_printf("Total card size: %u kBytes\n", CardSize.Total);
		trace_printf("Free card size:  %u kBytes\n", CardSize.Free);

  		// WRITE STRING
  		if ((fres = f_open(&fil, "SD:/second.txt",FA_CREATE_ALWAYS|FA_READ | FA_WRITE)) == FR_OK) {
  			// Read SDCARD size
  			f_puts("Hello world\n",&fil);
  			// Close file
  			f_close(&fil);

  		}

  		//READ IT BACK
  		if ((fres = f_open(&fil, "SD:/second.txt",FA_OPEN_ALWAYS |FA_READ | FA_WRITE)) == FR_OK) {
  		  			// Read SDCARD size
  					f_gets(buffer,50,&fil);
  		  			trace_printf("%s",buffer);
  		  			// Close file
  		  			f_close(&fil);

  		  		}
  		//unmount SD card!
  		f_mount(NULL, "SD:", 1);
  	}

  while (1) {
	  TM_RTC_GetDateTime(&datetime,TM_RTC_Format_BIN);
	  trace_printf("Time is: %u:%u:%u\n",datetime.Hours,datetime.Minutes,datetime.Seconds);
  }
  */

}

#pragma GCC diagnostic pop

// ----------------------------------------------------------------------------
