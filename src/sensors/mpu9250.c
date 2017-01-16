#include "sensors/mpu9250.h"

extern struct int_param_s* stm32mpu;
//extern unsigned short mpu_gyro_fsr[2];
//extern unsigned char mpu_acc_fsr[1];

uint16_t MPU_read(MPU_measurement *mbuffer){
	if(dmp_read_fifo(&mbuffer->gyro, &mbuffer->accel, &mbuffer->quat,
	   mbuffer->timestamp, &mbuffer->sensors, &mbuffer->more) == 0){
		/*while (i < 3) {
			x = mpu_acc_fsr[1];
			mbuffer->accel[i] = (mbuffer->accel[i]);///scales
			mbuffer->gyro[i] = (mbuffer->gyro[i]);///mpu_gyro_fsr[1]); //scale
			i++;
		}*/
		return 0;
	}
	return 1;
}
void MPU_selftest(void){
	long gyroBias[3];
	long accelBias[3];
	int result = mpu_run_self_test(gyroBias, accelBias);

	if (result == 0x7){
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

		trace_printf("Biases: %ld %ld %ld %ld %ld %ld\n\r", gyroBias[0], gyroBias[1], gyroBias[2], accelBias[0], accelBias[1], accelBias[2]);
	}
}

#include "init.h"

void MPU_init(){
	if(mpu_init(stm32mpu)) {
		trace_printf("MPU INIT FAILED");
		initStatus=MPU_INIT_FAIL;

	}
	if(mpu_set_sensors(INV_XYZ_GYRO | INV_XYZ_ACCEL| INV_XYZ_COMPASS)) {
		trace_printf("SENSOR SETTINGS ERROR!");
	}
	if(mpu_configure_fifo(INV_XYZ_GYRO|INV_XYZ_ACCEL)) {
		trace_printf("FIFO ERROR!");
	}
	if(mpu_set_sample_rate(MPU_SAMPLING_RATE)) {
		trace_printf("SETTINGS SAMPLE RATE ERROR!");
	}
	if(mpu_set_compass_sample_rate(MPU_SAMPLING_RATE)){
		trace_printf("COMPASS SETTINGS ERROR!");
	}
	if(dmp_load_motion_driver_firmware()) {
		trace_printf("MPU FIRMWARE ERROR!");
	}
	if(dmp_enable_feature(DMP_FEATURE_6X_LP_QUAT|DMP_FEATURE_SEND_RAW_ACCEL|DMP_FEATURE_SEND_CAL_GYRO|DMP_FEATURE_GYRO_CAL)) {
	trace_printf("DMP ERROR!");
	}
	if(dmp_set_fifo_rate(MPU_SAMPLING_RATE)){
		trace_printf("FIFORATE ERROR!");
	}
	if(dmp_enable_gyro_cal(1)){
		trace_printf("GYRO CALL ERROR!");
	}
	if(mpu_set_dmp_state(1)){
		trace_printf("DMP STATE ERROR!");
	}
	//if(dmp_enable_lp_quat(1)){
		//trace_printf("QUAT STATE ERROR!");
	//}
	//mpu_get_accel_fsr(mpu_acc_fsr);
	//mpu_get_gyro_fsr(mpu_gyro_fsr);

	//TODO: set interrupt PIN
}

