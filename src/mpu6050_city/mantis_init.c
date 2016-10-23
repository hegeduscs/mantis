/*
 * mantis_init.c

 *
 *  Created on: 2016. okt. 18.
 *      Author: Attila E. Franko
 */
#include "TM_lib/tm_stm32_adc.h"
#include "mpu6050_city/inv_mpu.h"
#include "mpu6050_city/inv_mpu_dmp_motion_driver.h"
#include "mpu6050_city/mantis_init.h"
#include "mpu6050_city/mantis_hih.h"
#include "TM_lib/tm_stm32_delay.h"
#include "diag/Trace.h"
#include "BlinkLed.h"
#include "TM_lib/tm_stm32_gpio.h"

extern struct int_param_s* stm32mpu;
extern char logRequired;
extern unsigned short mpu_gyro_fsr[2];
extern unsigned char mpu_acc_fsr[1];

void mantis_mpu_init(void)
{
	if(mpu_init(stm32mpu))
		    {
				char blinkStatus = 0;
		    	trace_printf("MPU INIT ERROR!");
		    	while(1)
		    	{
		    		if (blinkStatus)
		    		{
		    			//was On
		    			blink_led_off();
		    			blinkStatus=0;
		    		}
		    		else
		    		{
		    			//was Off
		    			blink_led_on();
		    			blinkStatus=1;
		    		}
		    		Delayms(500);
		    	}
		    }
		    if(mpu_set_sensors(INV_XYZ_GYRO | INV_XYZ_ACCEL| INV_XYZ_COMPASS))
		    {
		    	trace_printf("SENSOR SETTINGS ERROR!");
		    }
		    if(mpu_configure_fifo(INV_XYZ_GYRO|INV_XYZ_ACCEL))
		    {
		    	trace_printf("FIFO ERROR!");
		    }
		    if(mpu_set_sample_rate(MPU_SAMPLING_RATE))
		    {
		    	trace_printf("SETTINGS SAMPLE RATE ERROR!");
		    }
		    if(mpu_set_compass_sample_rate(MPU_SAMPLING_RATE))
		    {
		    	trace_printf("COMPASS SETTINGS ERROR!");
		    }
		    if(dmp_load_motion_driver_firmware())
		    {
		    	trace_printf("MPU FIRMWARE ERROR!");
		    }
			if(dmp_enable_feature(DMP_FEATURE_6X_LP_QUAT|DMP_FEATURE_SEND_RAW_ACCEL|DMP_FEATURE_SEND_CAL_GYRO|DMP_FEATURE_GYRO_CAL))
			{
				trace_printf("DMP ERROR!");
			}
			if(dmp_set_fifo_rate(MPU_SAMPLING_RATE))
			{
				trace_printf("FIFORATE ERROR!");
			}
			if(dmp_enable_gyro_cal(1))
			{
				trace_printf("GYRO CALL ERROR!");
			}
			if(mpu_set_dmp_state(1))
			{
				trace_printf("DMP STATE ERROR!");
			}
			if(dmp_enable_lp_quat(1))
			{
				trace_printf("QUAT STATE ERROR!");
			}
			mpu_get_accel_fsr(mpu_acc_fsr);
			mpu_get_gyro_fsr(mpu_gyro_fsr);
		//IT pin
		TM_GPIO_SetPinAsInput(GPIOC, GPIO_Pin_7);
}
void mantis_init(void)
{
	mantis_mpu_init();
	/*if(hih_init())
	{
		trace_printf("Hih Sensor init failed! \n");
	}*/
	TM_ADC_Init(VIB_ADC, VIB_SENSOR_CH);
	//TM_ADC_Init(DUST_ADC, DUST_SENSOR_CH);
}
void mantis_mpu_selftest(void)
{
	long gyroBias[3];
	long accelBias[3];
	int result = mpu_run_self_test(gyroBias, accelBias);

	if (result == 0x7)
	{
		float sens;
	    unsigned short accel_sens;

	    mpu_get_gyro_sens(&sens);

	    gyroBias[0] = (long)(gyroBias[0] * sens);
	    gyroBias[1] = (long)(gyroBias[1] * sens);
		gyroBias[2] = (long)(gyroBias[2] * sens);
		dmp_set_gyro_bias(gyroBias);
		mpu_get_accel_sens(&accel_sens);
		accelBias[0] *= accel_sens;
		accelBias[1] *= accel_sens;
		accelBias[2] *= accel_sens;
		dmp_set_accel_bias(accelBias);

		char logstr[128];
		trace_printf(logstr, "Biases: %ld %ld %ld %ld %ld %ld\n\r", gyroBias[0], gyroBias[1], gyroBias[2], accelBias[0], accelBias[1], accelBias[2]);
	}
}
uint16_t mantis_mpu_read(MPUBUFFER *mbuffer)
{
	uint16_t  i = 0;
	//short x;
//	if(TM_GPIO_GetInputPinValue(GPIOC, GPIO_Pin_7) == 0)
//	{
		if(dmp_read_fifo(&mbuffer->gyro, &mbuffer->accel, &mbuffer->quat, mbuffer->timestamp, &mbuffer->sensors, &mbuffer->more) == 0)
		{
			/*while(i < 3)
			{
				x = mpu_acc_fsr[1];
				mbuffer->accel[i] = (mbuffer->accel[i]);///scales
				mbuffer->gyro[i] = (mbuffer->gyro[i]);///mpu_gyro_fsr[1]); //scale
				i++;
			}*/
			return 1;
		}
//	}
	return 0;
}
