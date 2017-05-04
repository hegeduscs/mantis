#include "main.h"
#include "stm32f4xx_hal.h"
#include "fatfs.h"
#include "init.h"
#include "utils.h"
#include "logging.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "sensors/mpu9250.h"
#include "sensors/hih6030.h"
#include "sensors/dust.h"

/* Hardware handler global variables ---------*/
I2C_HandleTypeDef hi2c2;

SD_HandleTypeDef hsd;
HAL_SD_CardInfoTypedef SDCardInfo;

TIM_HandleTypeDef htim1; //blink error on LEDs 1Hz
TIM_HandleTypeDef htim2; //30 sec periodical timer for meas
TIM_HandleTypeDef htim3; //10 minute timer for logging

ADC_HandleTypeDef hadc3;

UART_HandleTypeDef huart2;
UART_HandleTypeDef huart3;
UART_HandleTypeDef huart6;


/*fatFs global variables ------------------*/
FATFS FS;
FIL log1,log_mpu,log_debug,log_bin;
FRESULT fres;

char currentFileName[100];

/* operational global variables ----------*/
char initStatus = INIT_OK;
char sdStatus = INIT_OK;

char inputBuffer[100];
char outputBuffer[100];

struct int_param_s* stm32mpu;
MPU_measurement mpuBuffer;

int main(void)
{

  initSystem();

  //if init failed, the status code will be blinked through the error LED
  if (initStatus!=INIT_OK&&initStatus<ERROR_RTC_NOT_SET) {
	  //blink out the error
		  for (int i=0;i<2*initStatus;i++) {
			  toggleLED(LED_RED);
			  HAL_Delay(250);
		  }
	  //perform system reset
	  HAL_NVIC_SystemReset();
  }

  openLogFile();
  openDebugFile();
  openBinaryFile();

  //STARTUP
  //enable interrupts for UART3, TIM2,TIM3, buttons
  MX_NVIC_Init();
  //enable debug UART interface
  HAL_UART_Receive_IT(&huart3,inputBuffer,1);

  MPU_init();
  MPU_selftest();

  HIH_init();


  //LED tests
  //for (uint8_t i=0;i<127;i++) {
	//  toggleLED(LED_ERROR);
	//  toggleLED(LED_SD);
	//  toggleLED(LED_MEAS);
	//  toggleLED(LED_RTC);
	//  HAL_Delay(300);
  //}

  //MAIN LOOP
  while (1)
  {
	  char buffer[100];
	  TM_RTC_t timeBuffer;
	  TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);
	  if (MPU_read(&mpuBuffer)==0) {
		  snprintf(buffer,200,"%u:%u:%u;%d;%d;%d;%d;%d;%d",timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds,mpuBuffer.accel[0],mpuBuffer.accel[1],mpuBuffer.accel[2],
				  mpuBuffer.gyro[0],mpuBuffer.gyro[1],mpuBuffer.gyro[2]);
		  f_printf(&log_debug,"%s\n",buffer);
		  //f_sync(&log1);
		  binary_log(mpuBuffer);
	} else {
		  //f_printf(&log1,"NO_FIFO\n");
		  //f_sync(&log1);
	}



  }

}





