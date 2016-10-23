/*
 * mantis_hih.c
 *
 *  Created on: 2016. okt. 13.
 *      Author: Attila E. Franko
 *      BME-TMIT
 */

#include "TM_lib/tm_stm32_i2c.h"
#include "mpu6050_city/mantis_hih.h"

int hih_init(void)
{
	if(TM_I2C_Init(HIH_I2C, HIH_PINSPACK, I2C_CLOCK) != TM_I2C_Result_Ok)
	{
		return -1;
	}
	if (TM_I2C_IsDeviceConnected(HIH_I2C, HIH_ADD << 1) != TM_I2C_Result_Ok)
	{
	    /* Return error */
	    return -1;
	}

	return 0;
}

struct HIH_BUFF read_hih(struct HIH_BUFF buffer)
{
	uint8_t data[4];
	uint16_t temp_humidity;
	uint16_t temp_temperature;

	if(TM_I2C_ReadMulti(HIH_I2C, HIH_ADD << 1, NULL, data, 4) != TM_I2C_Result_Ok) //TODO pointer
	{
		buffer.humidity = 0;
		buffer.temperature = 0;
	}
	//Masking MSB (status) bits
	temp_humidity = ((data[0] & ((uint8_t)0x3FU)) << 8) | data[1]; //TODO maszkolást meg kell nézni
	//Masking LSB (don't care) bits
	temp_temperature = (data[2] << 8) | (data[3] & ((uint8_t)0xFCU));
	//The last two bits -> don't care
	temp_temperature = temp_temperature >> 2;
	//SCALE AND CAST
	buffer.humidity = (double)(((unsigned int) temp_humidity) * 100 / (pow(2,14) - 1));
	buffer.temperature = (double) (((unsigned int) temp_temperature) / (pow(2, 14) - 1) * 165 - 40);
	return buffer;
}

