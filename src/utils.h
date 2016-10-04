/*
 * utils.h
 *
 *  Created on: 2016. okt. 4.
 *      Author: Csaba Hegedûs
 */

#ifndef UTILS_H_
#define UTILS_H_

#include "TM_lib/tm_stm32_fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "TM_lib/tm_stm32_mpu6050.h"
#include "diag/Trace.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"


void writeLogEntry (FIL*, TM_RTC_t, TM_MPU6050_t, uint16_t);

#endif /* UTILS_H_ */
