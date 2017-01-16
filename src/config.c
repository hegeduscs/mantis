#include "config.h"
#include "TM_lib/tm_stm32_rtc.h"
#include "diag/Trace.h"
extern UART_HandleTypeDef huart3;
char inputBuffer[100];
char outputBuffer[100];

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart) {
	TM_RTC_t timeBuffer;
	int id1;
	int id2;

	switch (inputBuffer[0]) {

	case '?': //help mode
		strcpy(outputBuffer,"T:update time, C:get time, M:runtime in millis, I:get ID, S: set ID, REBOOT: reboots\n");
		HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		break;

	case 'T': //time and date is being written
		HAL_UART_Receive(&huart3,inputBuffer,100,20);
			if (TM_RTC_SetDateTimeString(inputBuffer)==TM_RTC_Result_Ok) {
				strcpy(outputBuffer,"Time set.\n");
				HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
				trace_printf("Time was set:%s\n",inputBuffer);
			} else //failed to set RTC time
			{
				strcpy(outputBuffer,"Wrong input. Format: DD.MM.YY.weekday;hh:mm:ss\n");
				HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
			}

		break;

	case 'C': //current time and date to be printed
		TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);
		snprintf(outputBuffer,100,"Current time is: %u-%u-%u %u:%u:%u\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day,timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds);
		HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),100);
		break;

	case 'M': //returns current millis
		snprintf(outputBuffer,100,"Millis since startup:%d\n",HAL_GetTick());
		HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		break;

	case 'I': //retrieve ID
		id1=isValidConfig();
		if (id1) {
			trace_printf("Current ID is:%d",id1);
			snprintf(outputBuffer,"ID is:%d\n",id1);
			HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		} else {
			snprintf(outputBuffer,100,"No ID is set!\n");
			HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		}
		break;

	case 'S': //set ID
		HAL_UART_Receive(&huart3,inputBuffer,10,10);
		char temp=0;
		if (sscanf(inputBuffer,"%d",&temp)) {
			snprintf(outputBuffer,100,"ID was set:%d\n",temp);
			trace_printf(outputBuffer);
			HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
			writeConfig(temp);

		} else {
			snprintf(outputBuffer,100,"Bad ID format. ID range: 1-255\n");
			HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		}
		break;

	case 'R':
		HAL_UART_Receive(&huart3,inputBuffer,10,10);
		if (strcmp("EBOOT\n",inputBuffer)==0) HAL_NVIC_SystemReset();
		break;

	case '\0':
	default:
		trace_printf("UART receive error.\n");
		strcpy(outputBuffer,"Send ? for available commands.\n");
		HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),100);
		break;

	}
	//re-enable
	inputBuffer[0] = '\0';
	outputBuffer[0] = '\0';
	HAL_UART_Receive_IT(&huart3, inputBuffer, 1);
}

int isValidConfig() {
	int id1,id2;
	id1=TM_RTC_ReadBackupRegister(RTC_ID_LOCATION1);
	id2=TM_RTC_ReadBackupRegister(RTC_ID_LOCATION2);
	if (id1==id2&&id1!=0) return id1; else return 0;
}

void writeConfig(int ID) {
	TM_RTC_WriteBackupRegister(RTC_ID_LOCATION1,ID);
	TM_RTC_WriteBackupRegister(RTC_ID_LOCATION2,ID);
}
