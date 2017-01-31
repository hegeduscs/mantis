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
	case LED_RED: //PD3 -- red
		if (LEDs[1]) { //was on
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_3, GPIO_PIN_RESET);
			LEDs[1]=0;
		} else { //was off
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_3, GPIO_PIN_SET);
			LEDs[1]=1;
		}
		break;
	case LED_GREEN: //PD4- green
		if (LEDs[2]) { //was on
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_4, GPIO_PIN_RESET);
			LEDs[2]=0;
		} else { //was off
			HAL_GPIO_WritePin(GPIOD,GPIO_PIN_4, GPIO_PIN_SET);
			LEDs[2]=1;
		}
		break;
	case LED_YELLOW:  //PD7 - yellow
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
	//if TIM4 enabled, this will toggle SD or CONFIG leds 0.5Hz
	if (initStatus == ERROR_RTC_NOT_SET) {
		toggleLED(LED_YELLOW);
	}
	if (sdStatus != INIT_OK) {
		toggleLED(LED_SD);
	}
}


