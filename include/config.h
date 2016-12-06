/*
 * config.h
 *
 *  Created on: 2016. dec. 6.
 *      Author: Csaba Hegedûs
 */

#ifndef CONFIG_H_
#define CONFIG_H_

#include "stm32f4xx_hal.h"

#define RTC_ID_LOCATION1 RTC_BKP_DR0
#define RTC_ID_LOCATION2 RTC_BKP_DR1

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart);
void writeConfig(int ID);
int isValidConfig();

#endif /* CONFIG_H_ */
