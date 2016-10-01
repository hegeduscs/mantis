#ifndef INIT_H_
#define INIT_H_

#include "stm32f4xx.h"
#include "stm32f4xx_hal.h"

#include "BlinkLed.h"
#include "TM_lib/tm_stm32_delay.h"
#include "TM_lib/tm_stm32_fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "TM_lib/tm_stm32_mpu6050.h"

extern FATFS FS;
extern FIL fil;
extern FRESULT fres;
extern char initStatus;
extern TM_MPU6050_t mpu_buffer;
TM_RTC_t currentTime;

void initSystem();
void initRTC();
void initSD();
void initMPU();

#endif
