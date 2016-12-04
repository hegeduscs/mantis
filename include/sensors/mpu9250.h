/*
 * mpu9250.h
 *
 *  Created on: 2016. nov. 20.
 *      Author: Csaba Hegedûs
 */

#ifndef SENSORS_MPU9250_H_
#define SENSORS_MPU9250_H_

#include "utils.h"
#include "inv_mpu.h"
#include "inv_mpu_dmp_motion_driver.h"


//#define AK89xx_SECONDARY - Az MPU6050 ilyet nem tud, a 9250-ben xx=63, a 9150-ben xx=75
#define MPU_SAMPLING_RATE 100

typedef struct MPU_measurement
{
	short gyro[3];
	short accel[3];
	long quat[4];
	unsigned long timestamp;
	short sensors[1];
	unsigned char more[1];
} MPU_measurement;

void MPU_init();
void MPU_selftest(void);
uint16_t MPU_read(MPU_measurement *buffer);

#endif /* SENSORS_MPU9250_H_ */
