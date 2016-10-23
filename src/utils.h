/*
 * utils.h
 *
 *  Created on: 2016. okt. 4.
 *      Author: Csaba Heged�s
 */

#ifndef UTILS_H_
#define UTILS_H_

#include "TM_lib/tm_stm32_fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "mpu6050_city/mantis_init.h"
#include "diag/Trace.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"


void writeLogEntry (FIL*, TM_RTC_t, MPUBUFFER*, uint16_t);

#endif /* UTILS_H_ */
