#include "init.h"
#include "sensors/mpu9250.h"

void initSystem () {
	HAL_Init();
	initRCC();
	GPIO_Init();
	initRTC();
	initSD();
	initADC();
	initI2C();
	initTIMs();
	initUARTs();
}


void initSD() {
	//init SDIO module, later it will change to 4BIT mode
	hsd.Instance = SDIO;
	hsd.Init.ClockEdge = SDIO_CLOCK_EDGE_RISING;
	hsd.Init.ClockBypass = SDIO_CLOCK_BYPASS_DISABLE;
	hsd.Init.ClockPowerSave = SDIO_CLOCK_POWER_SAVE_DISABLE;
	hsd.Init.BusWide = SDIO_BUS_WIDE_1B;
	hsd.Init.HardwareFlowControl = SDIO_HARDWARE_FLOW_CONTROL_DISABLE;
	hsd.Init.ClockDiv = 0;
	MX_FATFS_Init();

	if (f_mount(&FS, "SD1", 1) != FR_OK) {
		initStatus=ERROR_NO_MOUNT; //can't mount SD card
	}
}

void initRCC() {
	 RCC_OscInitTypeDef RCC_OscInitStruct;
	 RCC_ClkInitTypeDef RCC_ClkInitStruct;

	 /**Configure the main internal regulator output voltage */
	  __HAL_RCC_PWR_CLK_ENABLE();

	  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

	  /**Initializes the CPU, AHB and APB busses clocks */
	  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;//|RCC_OSCILLATORTYPE_LSE;
	  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
	  //RCC_OscInitStruct.LSEState = RCC_LSE_ON;
	  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
	  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
	  RCC_OscInitStruct.PLL.PLLM = 12;
	  RCC_OscInitStruct.PLL.PLLN = 336;
	  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;
	  RCC_OscInitStruct.PLL.PLLQ = 7;
	  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
	  {
		initStatus = RCC_INIT_ERROR;
	  }

	  /**Initializes the CPU, AHB and APB busses clocks   */
	  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
	                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
	  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
	  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
	  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
	  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;

	  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5) != HAL_OK)
	  {
		//TODO: error handling
	    //Error_Handler();
	  }
// if need to manually enable RTC LSE clock, but included in TM lib
//	  PeriphClkInitStruct.PeriphClockSelection = RCC_PERIPHCLK_RTC;
//	  PeriphClkInitStruct.RTCClockSelection = RCC_RTCCLKSOURCE_LSE;
//	  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInitStruct) != HAL_OK)
//	   {
//	     //Error_Handler();
//	   }
//	  __HAL_RCC_RTC_ENABLE();

	  /**Configure the Systick interrupt time*/
	  HAL_SYSTICK_Config(HAL_RCC_GetHCLKFreq()/1000);

	  /**Configure the Systick */
	  HAL_SYSTICK_CLKSourceConfig(SYSTICK_CLKSOURCE_HCLK);

	  /* SysTick_IRQn interrupt configuration */
	  HAL_NVIC_SetPriority(SysTick_IRQn, 0, 0);
}

void GPIO_Init() {
	__HAL_RCC_GPIOC_CLK_ENABLE();
	__HAL_RCC_GPIOF_CLK_ENABLE();
	__HAL_RCC_GPIOH_CLK_ENABLE();
	__HAL_RCC_GPIOA_CLK_ENABLE();

	//H407 onboard LED
	GPIO_InitTypeDef GPIO_InitStructure;
	GPIO_InitStructure.Pin = GPIO_PIN_13;
	GPIO_InitStructure.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStructure.Speed = GPIO_SPEED_FAST;
	GPIO_InitStructure.Pull = GPIO_PULLUP;
	HAL_GPIO_Init(GPIOC, &GPIO_InitStructure);
	HAL_GPIO_WritePin(GPIOC,GPIO_PIN_13, GPIO_PIN_SET);
	//TODO: init GPIO pin-s


	//USART2 PD5, PD6 config
	__HAL_RCC_GPIOD_CLK_ENABLE();
	GPIO_InitTypeDef GPIO_InitStructure_USART;
	GPIO_InitStructure_USART.Pin = GPIO_PIN_5|GPIO_PIN_6;
	GPIO_InitStructure_USART.Mode = GPIO_MODE_AF_PP;
	GPIO_InitStructure_USART.Pull = GPIO_PULLUP;
	GPIO_InitStructure_USART.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	GPIO_InitStructure_USART.Alternate = GPIO_AF7_USART2;
	HAL_GPIO_Init(GPIOD, &GPIO_InitStructure_USART);

	//I2C2: PF0, PF1
	GPIO_InitTypeDef GPIO_InitStructure_I2C2;
	GPIO_InitStructure_I2C2.Pin = GPIO_PIN_0|GPIO_PIN_1;
	GPIO_InitStructure_I2C2.Mode = GPIO_MODE_AF_OD;
	GPIO_InitStructure_I2C2.Pull = GPIO_PULLUP;
	GPIO_InitStructure_I2C2.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	GPIO_InitStructure_I2C2.Alternate = GPIO_AF4_I2C2;
	HAL_GPIO_Init(GPIOF, &GPIO_InitStructure_I2C2);

	//USART3 GPIO Configuration: command and debug line, PB10-TX, PB11-RX
	__GPIOB_CLK_ENABLE();
	GPIO_InitTypeDef GPIO_InitStruct;
	GPIO_InitStruct.Pin = GPIO_PIN_10|GPIO_PIN_11;
	GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
	GPIO_InitStruct.Pull = GPIO_PULLUP;
	GPIO_InitStruct.Speed = GPIO_SPEED_HIGH;
	GPIO_InitStruct.Alternate = GPIO_AF7_USART3;
	HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

	//ADC3: PF3 for dust sensor
	GPIO_InitTypeDef GPIO_InitStruct_adc;
	GPIO_InitStruct_adc.Pin = GPIO_PIN_3;
	GPIO_InitStruct_adc.Mode = GPIO_MODE_ANALOG;
	GPIO_InitStruct_adc.Pull = GPIO_NOPULL;
	HAL_GPIO_Init(GPIOF, &GPIO_InitStruct_adc);

}

void initADC() {
	//ADC3
	__HAL_RCC_ADC3_CLK_ENABLE();
	ADC_ChannelConfTypeDef sConfig;
    hadc3.Instance = ADC3;
	hadc3.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV4;
	hadc3.Init.Resolution = ADC_RESOLUTION_12B;
	hadc3.Init.ScanConvMode = DISABLE;
	hadc3.Init.ContinuousConvMode = DISABLE;
	hadc3.Init.DiscontinuousConvMode = DISABLE;
	hadc3.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
	hadc3.Init.DataAlign = ADC_DATAALIGN_RIGHT;
	hadc3.Init.NbrOfConversion = 1;
	hadc3.Init.DMAContinuousRequests = DISABLE;
	hadc3.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
	if (HAL_ADC_Init(&hadc3) != HAL_OK) initStatus=ERROR_ADC_INIT;

	sConfig.Channel = ADC_CHANNEL_9;
	sConfig.Rank = 1;
	sConfig.SamplingTime = ADC_SAMPLETIME_28CYCLES;
	if (HAL_ADC_ConfigChannel(&hadc3, &sConfig) != HAL_OK) initStatus=ERROR_ADC_INIT;
}

void initUARTs() {

	//USART2: PD5 and PD6, for GSM modem
	huart2.Instance = USART2;
	huart2.Init.BaudRate = 115200;
	huart2.Init.WordLength = UART_WORDLENGTH_8B;
	huart2.Init.StopBits = UART_STOPBITS_1;
	huart2.Init.Parity = UART_PARITY_NONE;
	huart2.Init.Mode = UART_MODE_TX_RX;
	huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart2.Init.OverSampling = UART_OVERSAMPLING_16;
	if (HAL_UART_Init(&huart2) != HAL_OK)
	{
		initStatus = ERROR_UART_INIT;
	}
    __HAL_RCC_USART2_CLK_ENABLE();

	//hal_msp_init from CUBEMX code

	//USART3 for debug
	__USART3_CLK_ENABLE();
	huart3.Instance = USART3;
	huart3.Init.BaudRate = 115200;
	huart3.Init.WordLength = UART_WORDLENGTH_8B;
	huart3.Init.StopBits = UART_STOPBITS_1;
	huart3.Init.Parity = UART_PARITY_NONE;
	huart3.Init.Mode = UART_MODE_TX_RX;
	huart3.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart3.Init.OverSampling = UART_OVERSAMPLING_16;
	if(HAL_UART_Init(&huart3) != HAL_OK)
	{
	}
    __HAL_RCC_USART3_CLK_ENABLE();

}

void initRTC() {
// ALTERNATIVE MANUAL INITIALIZATION
//	 RCC_OscInitTypeDef RCC_OscInitStruct;
//	    uint32_t rtc_freq = 0;
//
//	    if(RTC->ISR == 7) {     // RTC initialization and status register (RTC_ISR), cold start (with no backup domain power) RTC reset value
//
//	    	hRTC.Instance = RTC;
//
//	        // Enable Power clock
//	        __PWR_CLK_ENABLE();
//
//	        // Enable access to Backup domain
//	        HAL_PWR_EnableBkUpAccess();
//
//	        // Reset Backup domain
//	        __HAL_RCC_BACKUPRESET_FORCE();
//	        __HAL_RCC_BACKUPRESET_RELEASE();
//
//	        // Enable LSE Oscillator
//	        RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_LSE;
//	        RCC_OscInitStruct.PLL.PLLState   = RCC_PLL_NONE; /* Mandatory, otherwise the PLL is reconfigured! */
//	        RCC_OscInitStruct.LSEState       = RCC_LSE_ON; /* External 32.768 kHz clock on OSC_IN/OSC_OUT */
//	        if (HAL_RCC_OscConfig(&RCC_OscInitStruct) == HAL_OK) {
//	            // Connect LSE to RTC
//	            __HAL_RCC_RTC_CLKPRESCALER(RCC_RTCCLKSOURCE_LSE);
//	            __HAL_RCC_RTC_CONFIG(RCC_RTCCLKSOURCE_LSE);
//	            rtc_freq = LSE_VALUE;
//	        } else {
//	            // Enable LSI clock
//	            RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_LSI | RCC_OSCILLATORTYPE_LSE;
//	            RCC_OscInitStruct.PLL.PLLState   = RCC_PLL_NONE; // Mandatory, otherwise the PLL is reconfigured!
//	            RCC_OscInitStruct.LSEState       = RCC_LSE_OFF;
//	            RCC_OscInitStruct.LSIState       = RCC_LSI_ON;
//	            rtc_freq=LSI_VALUE;
//	            if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK) {
//
//	            }
//	            // Connect LSI to RTC
//	            __HAL_RCC_RTC_CLKPRESCALER(RCC_RTCCLKSOURCE_LSI);
//	            __HAL_RCC_RTC_CONFIG(RCC_RTCCLKSOURCE_LSI);
//	            // [TODO] This value is LSI typical value. To be measured precisely using a timer input capture
//	            rtc_freq = LSI_VALUE;
//	        }
//
//	        // Enable RTC
//	        __HAL_RCC_RTC_ENABLE();
//
//	        hRTC.Init.HourFormat     = RTC_HOURFORMAT_24;
//	        hRTC.Init.AsynchPrediv   = 127;
//	        hRTC.Init.SynchPrediv    = (rtc_freq / 128) - 1;
//	        hRTC.Init.OutPut         = RTC_OUTPUT_DISABLE;
//	        hRTC.Init.OutPutPolarity = RTC_OUTPUT_POLARITY_HIGH;
//	        hRTC.Init.OutPutType     = RTC_OUTPUT_TYPE_OPENDRAIN;
//
//	        if (HAL_RTC_Init(&hRTC) != HAL_OK) {
//	        	initStatus = ERROR_IN_RTC_INIT;
//	        }
//	    }
	if (!TM_RTC_Init(TM_RTC_ClockSource_External)) {
		//RTC was first time initialized!
		configStatus= ERROR_RTC_NOT_SET;
		initStatus = ERROR_RTC_NOT_SET;
		TM_RTC_SetDateTimeString("01.01.15.5;00:00:01");
	}

	if (isValidConfig()==0) configStatus= ERROR_RTC_NOT_SET;

	TM_RTC_t timeBuffer;
	TM_RTC_GetDateTime(&timeBuffer,TM_RTC_Format_BIN);
	if (timeBuffer.Year<2016) configStatus = ERROR_RTC_NOT_SET;

	if (configStatus==ERROR_RTC_NOT_SET) {

	}
	trace_printf("Current time is:%u-%u-%u %u:%u:%u ",timeBuffer.Year,timeBuffer.Month,timeBuffer.Day,timeBuffer.Hours,timeBuffer.Minutes,timeBuffer.Seconds);

}

void initI2C() {
	__HAL_RCC_I2C2_CLK_ENABLE();
	hi2c2.Instance = I2C2;
	hi2c2.Init.ClockSpeed = 400000;
	hi2c2.Init.DutyCycle = I2C_DUTYCYCLE_2;
	hi2c2.Init.OwnAddress1 = 0;
	hi2c2.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
	hi2c2.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
	hi2c2.Init.OwnAddress2 = 0;
	hi2c2.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
	hi2c2.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;
	if (HAL_I2C_Init(&hi2c2) != HAL_OK)
	{
		initStatus = ERROR_I2C__INIT;
	}
}

void initTIMs() {

	 //INIT TIM2 for 30 second IT-s
	  TIM_ClockConfigTypeDef sClockSourceConfig;
	  TIM_MasterConfigTypeDef sMasterConfig;

	  //enable periphery CLK
	  //NOT in CUBEMX generated code!
	  __TIM2_CLK_ENABLE();


	  // TIMER2 gets the APB1 CLK which is 84MHz
	  //Prescaler is <65k, choosing 42000 --> 2kHz
	  //Counting to 60k gives us 30 seconds --> temperature and dust sensing
	  htim2.Instance = TIM2;
	  htim2.Init.Prescaler = 42000;
	  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
	  htim2.Init.Period = 60000;
	  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	  htim2.Init.RepetitionCounter = 0;
	  if (HAL_TIM_Base_Init(&htim2) != HAL_OK)  initStatus = ERROR_TIMER_INIT;

	  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
	  if (HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig) != HAL_OK)  initStatus = ERROR_TIMER_INIT;

	  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	  if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK) initStatus = ERROR_TIMER_INIT;

	  //HAL_TIM_Base_Init(&htim2);
	  HAL_TIM_Base_Start_IT(&htim2);

	  //--------------
	  //TIM3 for 10 minutes
	  __TIM3_CLK_ENABLE();
	  TIM_ClockConfigTypeDef sClockSourceConfig3;
	  TIM_MasterConfigTypeDef sMasterConfig3;
	  htim3.Instance=TIM3;
	  htim3.Init.Prescaler=42000;
	  htim3.Init.CounterMode = TIM_COUNTERMODE_UP;
	  htim3.Init.Period = 600000;
	  htim3.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
	  htim3.Init.RepetitionCounter = 0;
	  if (HAL_TIM_Base_Init(&htim3) != HAL_OK)  initStatus = ERROR_TIMER_INIT;

	  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
	  if (HAL_TIM_ConfigClockSource(&htim3, &sClockSourceConfig) != HAL_OK)  initStatus = ERROR_TIMER_INIT;
	  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	  if (HAL_TIMEx_MasterConfigSynchronization(&htim3, &sMasterConfig) != HAL_OK) initStatus = ERROR_TIMER_INIT;

	  HAL_TIM_Base_Start_IT(&htim3);
}

void MX_NVIC_Init(void)
{
  /* TIM2_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(TIM2_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(TIM2_IRQn);

  /* TIM3_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(TIM3_IRQn, 0, 1);
  HAL_NVIC_EnableIRQ(TIM3_IRQn);

  //UART3 Receive interrupt
  HAL_NVIC_SetPriority(USART3_IRQn, 1, 0);
  HAL_NVIC_EnableIRQ(USART3_IRQn);

}


