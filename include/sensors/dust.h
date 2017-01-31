#ifndef DUST_H
#define DUST_H

#include "stm32f4xx.h"
#include "stm32f4xx_hal.h"
#include "diag/Trace.h"
#include "init.h"

#define DUST_OK_LEVEL 10

int check_dust_sensor();
int dust_meas();

#endif
