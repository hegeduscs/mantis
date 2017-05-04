#ifndef LOGGING_H_
#define LOGGING_H_

#include "stm32f4xx_hal.h"
#include "fatfs.h"
#include "sensors/mpu9250.h"

extern FATFS FS;
extern FIL log1;
extern FIL log_mpu;
extern FIL log_debug;
extern FIL log_bin;
extern FRESULT fres;

extern char initStatus;
extern char configStatus;

#define MANTIS_MEAS_HEADER "TIMESTAMP;TEMP;HUMID\n"
#define MANTIS_MPU_HEADER "TODO\n"
#define MANTIS_MEAS_ENTRY_SIZE 100
#define DEBUG_LOG

void openFiles();
void writeLogEntry (FIL* fil, int type);
void createFile(int type);
void openDebugFile();
int checkSD();

extern MPU_measurement mpuBuffer;
void openBinaryFile();
void binary_log(MPU_measurement theBuff);

#endif /* LOGGING_H_ */
