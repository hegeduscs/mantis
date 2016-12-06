#include "utils.h"
#include "init.h"
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

void BlinkErrors() {
	//if TIM1 enabled, this will toggle SD or CONFIG leds 0.5Hz
	if (configStatus == ERROR_RTC_NOT_SET) {
		toggleLED(LED_RTC);
	}
	if (sdStatus != INIT_OK) {
		toggleLED(LED_SD);
	}
}

void startBlinking() {
	TIM_ClockConfigTypeDef sClockSourceConfig;
	TIM_MasterConfigTypeDef sMasterConfig;
	__TIM1_CLK_ENABLE();
	htim1.Instance = TIM1;
	htim1.Init.Prescaler = 42000;
	htim1.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim1.Init.Period = 2000;
	htim1.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	htim1.Init.RepetitionCounter = 0;
	HAL_TIM_Base_Init(&htim1);
	sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
	HAL_TIM_ConfigClockSource(&htim1, &sClockSourceConfig);
	sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	HAL_TIMEx_MasterConfigSynchronization(&htim1, &sMasterConfig);
	HAL_TIM_Base_Start_IT(&htim1);
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

