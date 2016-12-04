#ifndef INIT_H_
#define INIT_H_

#include "stm32f4xx.h"
#include "stm32f4xx_hal.h"
#include "diag/Trace.h"
#include "fatfs.h"
#include "TM_lib/tm_stm32_rtc.h"

//global fatFs variables in main.c
extern SD_HandleTypeDef hsd;
extern HAL_SD_CardInfoTypedef SDCardInfo;
extern FATFS FS;
extern FIL fil;

//global HW handlers in main.c
extern ADC_HandleTypeDef hadc3;
extern UART_HandleTypeDef huart2;
extern UART_HandleTypeDef huart3;
extern UART_HandleTypeDef huart6;
extern I2C_HandleTypeDef hi2c2;
extern TIM_HandleTypeDef htim2;
extern TIM_HandleTypeDef htim3;
extern char initStatus;

void initSystem();
void initRTC();
void initSD();
void initRCC();
void GPIO_Init();
void initADC();
void initRTC();
void initUARTs();
void initI2C();
void initTIMs();
void MX_NVIC_Init(void); //IT enabler

//init error codes
#define INIT_OK 0
#define RCC_INIT_ERROR 1
#define ERROR_NO_MOUNT 2
#define ERROR_FILE_OPEN 3
#define ERROR_RTC_NOT_SET 4
#define ERROR_TIMER_INIT 5
#define ERROR_UART_INIT 6
#define ERROR_I2C__INIT 7
#define MPU_INIT_FAIL 8
#define ERROR_ADC_INIT 9

#define MANTIS_MEAS_HEADER "TIMESTAMP;...\n"

#endif
