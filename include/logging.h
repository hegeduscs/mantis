#ifndef LOGGING_H_
#define LOGGING_H_

#include "stm32f4xx_hal.h"
#include "fatfs.h"

extern FATFS FS;
extern FIL log1;
extern FIL log_mpu;
extern FIL log_debug;
extern FRESULT fres;

extern char initStatus;
extern char configStatus;

#define MANTIS_MEAS_HEADER "TIMESTAMP,TEMP_AVG,TEMP_MIN,TEMP_MAX,DUST_AVG,DUST_DEV\n"
#define MANTIS_MPU_HEADER "TODO\n"

#define DEBUG_LOG

void openFiles();
void writeLogEntry (FIL* fil, int type);
void createFile(int type);
void openDebugFile();

#endif /* LOGGING_H_ */
