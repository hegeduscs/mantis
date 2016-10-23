//
// This file is part of the GNU ARM Eclipse distribution.
// Copyright (c) 2014 Liviu Ionescu.
//

// ----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include "diag/Trace.h"
#include <inttypes.h>

#include "init.h"
#include "BlinkLed.h"
#include "utils.h"

#include "stm32f407xx.h"
#include "TM_lib/tm_stm32_fatfs.h"
#include "TM_lib/tm_stm32_delay.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "TM_lib/tm_stm32_adc.h"
#include "mpu6050_city/mantis_hih.h"
#include "mpu6050_city/mantis_init.h"
#include "TM_lib/tm_stm32_usart.h"

// ----- main() ---------------------------------------------------------------

// Sample pragmas to cope with warnings. Please note the related line at
// the end of this function, used to pop the compiler diagnostics status.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"
#pragma GCC diagnostic ignored "-Wmissing-declarations"
#pragma GCC diagnostic ignored "-Wreturn-type"


UART_HandleTypeDef huart3;
GPIO_InitTypeDef GPIO_InitStruct;

void errorhandler(void)
{
	char blinkStatus = 0;
	while(1)
	{
		if (blinkStatus)
		{
		//was On
		blink_led_off();
		blinkStatus=0;
		}
		else
		{
		//was Off
		blink_led_on();
		blinkStatus=1;
		}
		Delayms(200);
	}
}

void MX_USART3_UART_Init(void)
{
	__GPIOB_CLK_ENABLE();
	__USART3_CLK_ENABLE();

	/**USART3 GPIO Configuration
 	PB10     ------> USART3_TX
	PB11     ------> USART3_RX
	*/
	GPIO_InitStruct.Pin = GPIO_PIN_10|GPIO_PIN_11;
	GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
	GPIO_InitStruct.Pull = GPIO_PULLUP;
	GPIO_InitStruct.Speed = GPIO_SPEED_HIGH;
	GPIO_InitStruct.Alternate = GPIO_AF7_USART3;
	HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

	huart3.Instance = USART3;
	huart3.Init.BaudRate = 115200;
	huart3.Init.WordLength = UART_WORDLENGTH_8B;
	huart3.Init.StopBits = UART_STOPBITS_1;
	huart3.Init.Parity = UART_PARITY_NONE;
	huart3.Init.Mode = UART_MODE_TX_RX;
	huart3.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart3.Init.OverSampling = UART_OVERSAMPLING_16;
	if(HAL_UART_Init(&huart3) != HAL_OK)
	{
		errorhandler();
	}
}

/* Fatfs structure */
FATFS FS;
FIL fil;
FRESULT fres;

/* Buffer variable */
char buffer[100];

// RTC buffers
TM_RTC_t datetime;

//Button object
TM_BUTTON_t* userButton;

//HIH object
HIH_BUFF hih_buff;

//MPU_city
struct int_param_s* stm32mpu;
MPUBUFFER the_buff;

//UART
HAL_StatusTypeDef UARTStatus;

//status variables
char blinkStatus;
char initStatus;
uint16_t logRequired;
char stopExecution;
unsigned short mpu_gyro_fsr[2];
unsigned char mpu_acc_fsr[1];

int main(int argc, char* argv[])
{
	/* Init system clock for maximum system speed */
	TM_RCC_InitSystem();

	/* Init HAL layer */
	int initStatus = initSystem();
	//MX_USART3_UART_Init();
	//uint8_t str[] = "HELLO";
	//UARTStatus =  HAL_UART_Transmit(&huart3, &str, 5, 5000); /* MaxCmdSize and MaxCmdTimeout depend on user application  */
	/* Init USART, TX: PC6, RX: PC7, 921600 bauds */
	//TM_USART_Init(USART3, TM_USART_PinsPack_1, 115200);

	/* Put test string */
	//TM_USART_Puts(USART3, "Hello world\n");

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

	//INIT global variables
	stopExecution=0;
    logRequired=0;

    /*INIT SENSORS*/

    mantis_mpu_selftest();

    /**
     * Using ADC for VIBRATION SESNOR
     */
    uint16_t adc_vib_result;
    //uint16_t adc_dust_result;
	while(!stopExecution)
	{
		/*PRINT MPU VALUES*/
		//TODO
		Delayms(10);
		logRequired = mantis_mpu_read(&the_buff);

		/*PRINT HIH VALUES*/
		/*hih_buff = read_hih(hih_buff);
		trace_printf("Humidity: %" PRIu16 "\n", hih_buff.humidity);
		trace_printf("Temperature: %" PRIu16 "\n", hih_buff.temperature);/*

		/*PRINT ADC VALUES*/
		/*adc_dust_result = TM_ADC_Read(ADC1, DUST_SENSOR_CH);
		trace_printf("%" PRIu16 "\n",adc_vib_result);
		trace_printf("%" PRIu16 "\n",adc_dust_result);*/

		if (logRequired != 0)
		{
		//	char buffer[20];
		//	snprintf(buffer,20,"%d ",logRequired);
			adc_vib_result = TM_ADC_Read(VIB_ADC, VIB_SENSOR_CH);

		//	TM_USART_Puts(USART3, buffer);
			TM_RTC_GetDateTime(&datetime,TM_RTC_Format_BIN);
			//writint into file
			writeLogEntry(&fil, datetime, &the_buff, adc_vib_result);
			//TODO: clear meas buffers
			logRequired=0;
		}

 		//TM_BUTTON_Update();

	}
	trace_printf("BYE\n");
	f_close(&fil);
  	f_mount(NULL, "SD:", 1);
  	Delayms(500);
}

void TM_RTC_WakeupHandler(void)
{
	//toggle LED-s, if init failed
	if (initStatus)
	{
		/*if (blinkStatus)
		{
			//was On
			blink_led_off();
			blinkStatus=0;

		}
		else
		{
			//was Off
			blink_led_on();
			blinkStatus=1;
		}*/
	}

	//logRequired=1;
}


#pragma GCC diagnostic pop

// ----------------------------------------------------------------------------
