#include "main.h"
#include "stm32f4xx_hal.h"
#include "fatfs.h"
#include "init.h"
#include "utils.h"
#include "TM_lib/tm_stm32_rtc.h"


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
FIL log1,log2,log_debug;
FRESULT fres;

/* operational global variables ----------*/
char initStatus = INIT_OK;
char configStatus = INIT_OK;
char sdStatus = INIT_OK;

char inputBuffer[100];
char outputBuffer[100];

struct int_param_s* stm32mpu;
//MPU_measurement mpuBuffer;

int main(void)
{

  initSystem();

  //if init failed, the status code will be blinked through the error LED
  if (initStatus) {
	  if (initStatus>3) //SD card mounted and files opened
	  {

	  }
	  //blink out the error
	  for (int runs=0;runs<2;runs++) {
		  for (int i=0;i<2*initStatus;i++) {
			  toggleLED(LED_ERROR);
			  HAL_Delay(250);
		  }
		  HAL_Delay(3000);
	  }
	  //perform system reset
	  HAL_NVIC_SystemReset();
  }

  //STARTUP
  //enable interrupts for UART3, TIM2,TIM3,
  MX_NVIC_Init();
  //enable debug UART interface
  HAL_UART_Receive_IT(&huart3,inputBuffer,1);

  //MPU_init();
  //MPU_selftest();


  //MAIN LOOP
  while (1)
  {

	 // trace_printf("%d\n",HAL_GPIO_ReadPin(GPIOD,GPIO_PIN_0));
	  //toggleLED(LED_ERROR);
	  //int timerValue =__HAL_TIM_GET_COUNTER(&htim2);
	  //trace_printf("value:%d\n",timerValue);
	  //HAL_UART_Transmit(&huart2,outputBuffer,4,1000);
	  //trace_printf("UART RECEIVE\n");
	  //HAL_UART_Receive(&huart2,inputBuffer,100,1000);
	  //trace_printf("%s\n",inputBuffer);
	 // HIH_readout hbuf;
	  //if (HIH_read(&hbuf)==HIH_OK) {}
	  //if (MPU_read(&mpuBuffer)==0) {
		//  trace_printf("%u,%u,%u\n",mpuBuffer.accel[0],mpuBuffer.accel[1],mpuBuffer.accel[2]);
	  //} else {
	//	  trace_printf("NO_FIFO\n");
	 // }
	  //HAL_UART_Transmit(&huart3,"MAIN\n",5,100);
	    //  HAL_Delay(1000);

	  //HAL_ADC_Start(&hadc3);
	  //if (HAL_ADC_PollForConversion(&hadc3,50)==HAL_OK) {
	//	  trace_printf("Value: %d\n",HAL_ADC_GetValue(&hadc3));
	  //}
	  //HAL_ADC_Stop(&hadc3);
  }

}





