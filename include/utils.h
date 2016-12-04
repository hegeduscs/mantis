/*
 * utils.h
 *
 *  Created on: 2016. okt. 4.
 *      Author: Csaba Heged�s
 */

#ifndef UTILS_H_
#define UTILS_H_

#include "diag/Trace.h"
#include "stm32f4xx_hal.h"
#include "fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"
#pragma GCC diagnostic ignored "-Wunused-parameter"



void toggleLED(int pinNumber);
void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart);
int I2C_ReadMulti(I2C_HandleTypeDef* I2C_handler, uint8_t device_address, uint8_t register_address, uint8_t* data, uint16_t count);


#define LED_ERROR 0
#define LED_SD 1
#define LED_MEAS 2
#define LED_RTC 3

#define RTC_ID_LOCATION1 RTC_BKP_DR0
#define RTC_ID_LOCATION2 RTC_BKP_DR1

#endif /* UTILS_H_ */
