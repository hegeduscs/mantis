################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/TM_lib/stm32f4xx_hal_msp.c \
../src/TM_lib/tm_stm32_button.c \
../src/TM_lib/tm_stm32_delay.c \
../src/TM_lib/tm_stm32_fatfs.c \
../src/TM_lib/tm_stm32_gpio.c \
../src/TM_lib/tm_stm32_i2c.c \
../src/TM_lib/tm_stm32_mpu6050.c \
../src/TM_lib/tm_stm32_rcc.c \
../src/TM_lib/tm_stm32_rtc.c 

OBJS += \
./src/TM_lib/stm32f4xx_hal_msp.o \
./src/TM_lib/tm_stm32_button.o \
./src/TM_lib/tm_stm32_delay.o \
./src/TM_lib/tm_stm32_fatfs.o \
./src/TM_lib/tm_stm32_gpio.o \
./src/TM_lib/tm_stm32_i2c.o \
./src/TM_lib/tm_stm32_mpu6050.o \
./src/TM_lib/tm_stm32_rcc.o \
./src/TM_lib/tm_stm32_rtc.o 

C_DEPS += \
./src/TM_lib/stm32f4xx_hal_msp.d \
./src/TM_lib/tm_stm32_button.d \
./src/TM_lib/tm_stm32_delay.d \
./src/TM_lib/tm_stm32_fatfs.d \
./src/TM_lib/tm_stm32_gpio.d \
./src/TM_lib/tm_stm32_i2c.d \
./src/TM_lib/tm_stm32_mpu6050.d \
./src/TM_lib/tm_stm32_rcc.d \
./src/TM_lib/tm_stm32_rtc.d 


# Each subdirectory must supply rules for building sources it contributes
src/TM_lib/stm32f4xx_hal_msp.o: ../src/TM_lib/stm32f4xx_hal_msp.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -Og -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -ffreestanding -fno-move-loop-invariants -Wall -Wextra  -g3 -DDEBUG -DUSE_FULL_ASSERT -DTRACE -DOS_USE_TRACE_SEMIHOSTING_DEBUG -DSTM32F407xx -DUSE_HAL_DRIVER -DHSE_VALUE=8000000 -I"../include" -I"../system/include" -I"../system/include/cmsis" -I"../system/include/stm32f4-hal" -std=gnu11 -Wno-missing-prototypes -Wno-missing-declarations -MMD -MP -MF"$(@:%.o=%.d)" -MT"src/TM_lib/stm32f4xx_hal_msp.d" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

src/TM_lib/%.o: ../src/TM_lib/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -Og -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -ffreestanding -fno-move-loop-invariants -Wall -Wextra  -g3 -DDEBUG -DUSE_FULL_ASSERT -DTRACE -DOS_USE_TRACE_SEMIHOSTING_DEBUG -DSTM32F407xx -DUSE_HAL_DRIVER -DHSE_VALUE=8000000 -I"../include" -I"../system/include" -I"../system/include/cmsis" -I"../system/include/stm32f4-hal" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


