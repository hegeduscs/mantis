/*
 * mantis_init.c

 *
 *  Created on: 2016. okt. 18.
 *      Author: Attila E. Franko
 */
#ifndef MPU6050_CITY_MANTIS_INIT_H_
#define MPU6050_CITY_MANTIS_INIT_H_

#include "TM_lib/tm_stm32_adc.h"
#include "mpu6050_city/inv_mpu.h"
#include "mpu6050_city/inv_mpu_dmp_motion_driver.h"
#include "mpu6050_city/mantis_init.h"
#include "mpu6050_city/mantis_hih.h"
#include "diag/Trace.h"

//#define AK89xx_SECONDARY - Az MPU6050 ilyet nem tud, a 9250-ben xx=63, a 9150-ben xx=75
#define MPU_SAMPLING_RATE							100

#define VIB_ADC										ADC3
#define DUST_ADC									ADC2

#define VIB_SENSOR_CH						 TM_ADC_Channel_14 //PF4!
#define DUST_SENSOR_CH 						 TM_ADC_Channel_6 //TODO

typedef struct MPUBUFFER
{
	short gyro[3];
	short accel[3];
	long quat[4];
	unsigned long timestamp;
	short sensors[1];
	unsigned char more[1];
} MPUBUFFER;

void mantis_init(void);
void mantis_mpu_selftest(void);
void mantis_mpu_init(void);
uint16_t mantis_mpu_read(MPUBUFFER *buffer);



#endif /* MPU6050_CITY_MANTIS_INIT_H_ */
