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

extern char initStatus;
extern char configStatus;
extern char sdStatus;
extern TIM_HandleTypeDef htim1;

void toggleLED(int pinNumber);
void BlinkErrors();

#define LED_SD 0
#define LED_RED 1
#define LED_GREEN 2
#define LED_YELLOW 3


#endif /* UTILS_H_ */
