#include "main.h"
#include "stm32f4xx_hal.h"
#include "fatfs.h"
#include "init.h"
#include "utils.h"
#include "logging.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "sensors/mpu9250.h"
#include "sensors/hih6030.h"

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
FIL log1,log_mpu,log_debug;
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

  //blink out if SD card is low on space and RTC is not set
  if (initStatus==ERROR_RTC_NOT_SET|sdStatus!=INIT_OK) {
	  startBlinking();
  }

  openLogFile();
  openDebugFile();

  //STARTUP
  //enable interrupts for UART3, TIM2,TIM3, buttons
  MX_NVIC_Init();
  //enable debug UART interface
  HAL_UART_Receive_IT(&huart3,inputBuffer,1);

  MPU_init();
  MPU_selftest();

  HIH_init();
  //MAIN LOOP

  //LED tests
  //for (uint8_t i=0;i<127;i++) {
	//  toggleLED(LED_ERROR);
	//  toggleLED(LED_SD);
	//  toggleLED(LED_MEAS);
	//  toggleLED(LED_RTC);
	//  HAL_Delay(300);
  //}
  //HAL_GPIO_WritePin(GPIOF,GPIO_PIN_2, GPIO_PIN_SET);

  while (1)
  {

	  //trace_printf("%d\n",HAL_ADC_);
	  //toggleLED(LED_ERROR);
	  //int timerValue =__HAL_TIM_GET_COUNTER(&htim2);
	  //trace_printf("value:%d\n",timerValue);
	  //HAL_UART_Transmit(&huart2,outputBuffer,4,1000);
	  //trace_printf("UART RECEIVE\n");
	  //HAL_UART_Receive(&huart2,inputBuffer,100,1000);
	  //trace_printf("%s\n",inputBuffer);
	 //HIH_readout hbuf;
	 //if (HIH_read(&hbuf)==HIH_OK) {
	  //char output[100];
	  //snprintf(output,100,"Temp:%f, %f \n",hbuf.temperature, hbuf.humidity);
	  //trace_printf("%s",output);
	  char buffer[100];
	  TM_RTC_t timeBuffer;
	  TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);
	  if (MPU_read(&mpuBuffer)==0) {
		  snprintf(buffer,200,"%u:%u:%u;%d;%d;%d",timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds,mpuBuffer.accel[0],mpuBuffer.accel[1],mpuBuffer.accel[2]);
		  f_printf(&log1,"%s\n",buffer);
		  f_sync(&log1);
	} else {
		  f_printf(&log1,"NO_FIFO\n");
		  f_sync(&log1);
	}
	//HAL_UART_Transmit(&huart3,"MAIN\n",5,100);
	 //HAL_Delay(500);
//	 HAL_GPIO_WritePin(GPIOF,GPIO_PIN_2, GPIO_PIN_SET);
//	 for (int i=0;i<100;i++);
//
//	  HAL_ADC_Start(&hadc3);
//	  if (HAL_ADC_PollForConversion(&hadc3,50)==HAL_OK) {
//		  trace_printf("Value: %d\n",HAL_ADC_GetValue(&hadc3));
//	  }
//	  HAL_ADC_Stop(&hadc3);
//	  HAL_GPIO_WritePin(GPIOF,GPIO_PIN_2, GPIO_PIN_SET);
//	  HAL_Delay(500);
  }

}





