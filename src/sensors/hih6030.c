#include "sensors/hih6030.h"
#include "math.h"
extern I2C_HandleTypeDef hi2c2;

int HIH_init() {
	if (HAL_I2C_IsDeviceReady(&hi2c2, HIH_ADDRESS << 1, 2, 5) != HAL_OK) {
			/* Return error */
			return HIH_FAIL;
		}
	return HIH_OK;
}

int HIH_read(HIH_readout* buffer) {
	uint8_t data[4];
	uint16_t temp_humidity;
	uint16_t temp_temperature;

	if(HAL_I2C_Master_Receive(&hi2c2, HIH_ADDRESS << 1,data, 4, 10) != HAL_OK) {
			buffer->humidity = 0;
			buffer->temperature = 0;
			return HIH_FAIL;
	}
	//trace_printf("%x %x %x %x\n",data[0],data[1],data[2],data[3]);
	//Masking MSB (status) bits
	temp_humidity = ((data[0] & ((uint8_t)0x3FU)) << 8) | data[1];
	//Masking LSB (don't care) bits
	temp_temperature = (data[2] << 8) | (data[3] & ((uint8_t)0xFCU));
	//The last two bits -> don't care
	temp_temperature = temp_temperature >> 2;

	//SCALE AND CAST
	buffer->humidity = (double)(((unsigned int) temp_humidity) * 100 / (pow(2,14) - 1));
	buffer->temperature = (double) (((unsigned int) temp_temperature) / (pow(2, 14) - 1) * 165 - 40);

	return HIH_OK;

}
