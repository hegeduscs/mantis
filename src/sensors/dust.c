#include "sensors/dust.h"

#pragma GCC push_options
#pragma GCC optimize ("O3")
void delayus(__IO uint32_t usecs) //20us-tõl elhanyagolható hibával
{
	CoreDebug->DEMCR &= ~0x01000000;
	CoreDebug->DEMCR |=  0x01000000;

	__IO uint32_t cycles = (SystemCoreClock/1000000L)*usecs;

	/* Enable counter */
	DWT->CTRL &= ~0x00000001;
	DWT->CTRL |=  0x00000001;

	__IO uint32_t prev_state = DWT->CYCCNT;
	do{}
	while(DWT->CYCCNT - prev_state < cycles);
}
#pragma GCC pop_options

int dust_meas()
{
	int meas=0;
	__disable_irq();
	HAL_GPIO_WritePin(GPIOF, GPIO_PIN_2, GPIO_PIN_RESET);

	delayus(280);

	HAL_ADC_Start(&hadc3);
	if (HAL_ADC_PollForConversion(&hadc3,50) == HAL_OK)
	{
		meas=HAL_ADC_GetValue(&hadc3);
	}

	HAL_ADC_Stop(&hadc3);

	delayus(40);

	HAL_GPIO_WritePin(GPIOF, GPIO_PIN_2, GPIO_PIN_SET);
	__enable_irq();
	return meas;
}

int check_dust_sensor() {
	for (int i=0;i<10;i++) {
		if (DUST_OK_LEVEL<dust_meas()) return INIT_OK;
		HAL_Delay(10);
	}
	return DUST_ERROR;
}

