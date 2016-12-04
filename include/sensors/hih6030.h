#ifndef HIH6030
#define HIH6030

#include "stm32f4xx_hal.h"
#include "utils.h"
typedef struct {
	double temperature;
	double humidity;
} HIH_readout;

#define HIH_ADDRESS	0x27

int HIH_init(void);
int HIH_read( HIH_readout* buffer);

#define HIH_OK 0
#define HIH_FAIL 1

#endif
