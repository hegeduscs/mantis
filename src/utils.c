#include "utils.h"

static uint8_t LEDs[5]={0,0,0,0,0};
void toggleLED(int pinNumber) {
	switch (pinNumber) {
	case LED_ERROR: //H407 onboard LED: ACTIVE_LOW
		if (LEDs[0]) { //was on
			HAL_GPIO_WritePin(GPIOC,GPIO_PIN_13, GPIO_PIN_SET);
			LEDs[0]=0;
		} else { //was off
			HAL_GPIO_WritePin(GPIOC,GPIO_PIN_13, GPIO_PIN_RESET);
			LEDs[0]=1;
		}
		break;
	case LED_SD: //PD1
		break;
	case LED_MEAS: //PD2
		break;
	case LED_RTC:  //PD3
		break;
	case 4:
		break;
	}
}

extern UART_HandleTypeDef huart3;
char inputBuffer[100];
char outputBuffer[100];

void HAL_UART_RxCpltCallback(UART_HandleTypeDef *huart) {
	TM_RTC_t timeBuffer;
	int id1;
	int id2;

	switch (inputBuffer[0]) {

	case '?': //help mode
		strcpy(outputBuffer,"T:update time, C:get time, R:runtime, I:get ID, S: set ID,\n");
		HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		break;

	case 'T': //time and date is being written
		HAL_UART_Receive(&huart3,inputBuffer,100,10);
		trace_printf("Time to set:%s\n",inputBuffer);
		if (sscanf(inputBuffer,"%d-%d-%d %d:%d:%d",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day,timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds) == 6){
			if (TM_RTC_SetDateTime(&inputBuffer,TM_RTC_Format_BIN) ==TM_RTC_Result_Ok) {
				strcpy(outputBuffer,"Time set.\n");
				HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
			} else //failed to set RTC time
			{
				strcpy(outputBuffer,"Wrong input. Format: YY-MM-DD hh:mm:ss\n");
				HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
			}

		} else { //bad input
			strcpy(outputBuffer,"Wrong input. Format: YY-MM-DD hh:mm:ss\n");
			HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		}

		break;

	case 'C': //current time and date to be printed
		TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);
		snprintf(outputBuffer,100,"Current time is: %u-%u-%u %u:%u:%u\n",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day,timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds);
		HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),100);
		break;

	case 'R': //returns current millis
		snprintf(outputBuffer,100,"Millis since startup:%d\n",HAL_GetTick());
		HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		break;

	case 'I': //retrieve ID
		id1=TM_RTC_ReadBackupRegister(RTC_ID_LOCATION1);
		id2=TM_RTC_ReadBackupRegister(RTC_ID_LOCATION2);
		if (id1==id2&&id1!=0) {
			trace_printf("Current ID is:%d",id1);
			snprintf(outputBuffer,"ID is:%d\n",id1);
			HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		} else {
			snprintf(outputBuffer,100,"No ID is set!\n");
			HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		}
		break;

	case 'S': //set ID
		HAL_UART_Receive(&huart3,inputBuffer,100,10);
		char temp=0;
		if (sscanf(inputBuffer,"%d",&temp)) {
			snprintf(outputBuffer,100,"ID to be set:%d\n",temp);
			trace_printf(outputBuffer);
			HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
			TM_RTC_WriteBackupRegister(RTC_ID_LOCATION1,temp);
			TM_RTC_WriteBackupRegister(RTC_ID_LOCATION2,temp);

		} else {
			snprintf(outputBuffer,100,"Bad ID format. ID range: 1-255\n");
			HAL_UART_Transmit(&huart3,outputBuffer,strlen(outputBuffer),10);
		}
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
	HAL_UART_Receive_IT(&huart3, inputBuffer, 1);
}



int I2C_ReadMulti(I2C_HandleTypeDef* I2C_handler, uint8_t device_address, uint8_t register_address, uint8_t* data, uint16_t count) {
	if (HAL_I2C_Master_Transmit(I2C_handler, (uint16_t)device_address, &register_address, 1, 1000) != HAL_OK) {
			/* Check error */
			if (HAL_I2C_GetError(I2C_handler) != HAL_I2C_ERROR_AF) {
				trace_printf("I2C_TRANSMIT_ERROR:%x\n",HAL_I2C_GetError(I2C_handler));
			}

			/* Return error */
			return HAL_I2C_STATE_ERROR;
		}

		/* Receive multiple byte */
		if (HAL_I2C_Master_Receive(I2C_handler, device_address, data, count, 1000) != HAL_OK) {
			/* Check error */
			if (HAL_I2C_GetError(I2C_handler) != HAL_I2C_ERROR_AF) {
				trace_printf("I2C_RECEIVE_ERROR:%x\n",HAL_I2C_GetError(I2C_handler));
			}

			/* Return error */
			return HAL_I2C_STATE_ERROR;
		}

		/* Return OK */
		return HAL_OK;
}

int I2C_WriteMulti (I2C_HandleTypeDef* Handle, uint8_t device_address, uint16_t register_address, uint8_t* data, uint16_t count) {
	if (HAL_I2C_Mem_Write(Handle, device_address, register_address, register_address > 0xFF ? I2C_MEMADD_SIZE_16BIT : I2C_MEMADD_SIZE_8BIT, data, count, 1000) != HAL_OK) {
			/* Check error */
			if (HAL_I2C_GetError(Handle) != HAL_I2C_ERROR_AF) {
				trace_printf("I2C_WRITE_ERROR:%x\n",HAL_I2C_GetError(Handle));
			}
			/* Return error */
			return HAL_I2C_STATE_ERROR;
		}
		/* Return OK */
		return HAL_OK;
}
