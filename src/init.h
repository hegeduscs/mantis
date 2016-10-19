#ifndef INIT_H_
#define INIT_H_

#include "stm32f4xx.h"
#include "stm32f4xx_hal.h"

#include "diag/Trace.h"

#include "BlinkLed.h"
#include "TM_lib/tm_stm32_delay.h"
#include "TM_lib/tm_stm32_fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "TM_lib/tm_stm32_mpu6050.h"
#include "TM_lib/tm_stm32_button.h"

extern FATFS FS;
extern FIL fil;
extern FRESULT fres;
extern char initStatus;
extern TM_MPU6050_t mpu_buffer;
extern TM_BUTTON_t* userButton;
static void BUTTON_Callback(TM_BUTTON_t* ButtonPtr, TM_BUTTON_PressType_t PressType);
TM_RTC_t currentTime;

void initSystem();
void initRTC();
void initSD();
void initMPU();
void initADC();
void initButtons();

#endif
