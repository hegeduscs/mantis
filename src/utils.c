#include "utils.h"
#include "init.h"
static char LEDs[5]={0,0,0,0,0};

void toggleLED(int pinNumber) {
	switch (pinNumber) {
	case LED_SD: //H407 onboard LED: ACTIVE_LOW
		if (LEDs[0]) { //was on
			HAL_GPIO_WritePin(GPIOC,GPIO_PIN_13, GPIO_PIN_SET);
			LEDs[0]=0;
		} else { //was off
			HAL_GPIO_WritePin(GPIOC,GPIO_PIN_13, GPIO_PIN_RESET);
			LEDs[0]=1;
		}
		break;
	case LED_ERROR: //PD3 -- red
		if (LEDs[1]) { //was on
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_3, GPIO_PIN_RESET);
			LEDs[1]=0;
		} else { //was off
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_3, GPIO_PIN_SET);
			LEDs[1]=1;
		}
		break;
	case LED_MEAS: //PD4- green
		if (LEDs[2]) { //was on
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_4, GPIO_PIN_RESET);
			LEDs[2]=0;
		} else { //was off
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_4, GPIO_PIN_SET);
			LEDs[2]=1;
		}
		break;
	case LED_RTC:  //PD7 - yellow
		if (LEDs[3]) { //was on
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_7, GPIO_PIN_RESET);
			LEDs[3]=0;
		} else { //was off
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_7, GPIO_PIN_SET);
			LEDs[3]=1;
		}
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

