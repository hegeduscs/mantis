################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/FatFs/diskio.c \
../src/FatFs/ff.c \
../src/FatFs/ff_gen_drv.c \
../src/FatFs/sd_diskio.c \
../src/FatFs/syscall.c 

OBJS += \
./src/FatFs/diskio.o \
./src/FatFs/ff.o \
./src/FatFs/ff_gen_drv.o \
./src/FatFs/sd_diskio.o \
./src/FatFs/syscall.o 

C_DEPS += \
./src/FatFs/diskio.d \
./src/FatFs/ff.d \
./src/FatFs/ff_gen_drv.d \
./src/FatFs/sd_diskio.d \
./src/FatFs/syscall.d 


# Each subdirectory must supply rules for building sources it contributes
src/FatFs/%.o: ../src/FatFs/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -mfloat-abi=soft -Og -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -ffreestanding -fno-move-loop-invariants -Wall -Wextra  -g3 -DDEBUG -DUSE_FULL_ASSERT -DTRACE -DOS_USE_TRACE_SEMIHOSTING_DEBUG -DSTM32F407xx -DUSE_HAL_DRIVER -DHSE_VALUE=12000000 -I"../include" -I"../system/include" -I"../system/include/cmsis" -I"../system/include/stm32f4-hal" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


