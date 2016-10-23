/*
 * mantis_hih.h
 *
 *  Created on: 2016. okt. 13.
 *      Author: Attila E. Franko
 *      BME-TMIT
 */

#include "TM_lib/tm_stm32_i2c.h"

#ifndef _MANTIS_HIH_H_
#define _MANTIS_HIH_H_

#define HIH_I2C							I2C2
#define HIH_PINSPACK					TM_I2C_PinsPack_1 // PB11 - SDA, PB10 - SCL
#define I2C_CLOCK						400000
#define HIH_ADD							0x27


typedef struct HIH_BUFF							//Buffer for the measurements
{
	double temperature;
	double humidity;
} HIH_BUFF;

int hih_init(void);
struct HIH_BUFF read_hih(struct HIH_BUFF buffer);

#endif /* _MANTIS_HIH_H_ */
