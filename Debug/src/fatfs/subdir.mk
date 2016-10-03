################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/fatfs/diskio.c \
../src/fatfs/fatfs_sd_sdio.c \
../src/fatfs/ff.c \
../src/fatfs/syscall.c 

OBJS += \
./src/fatfs/diskio.o \
./src/fatfs/fatfs_sd_sdio.o \
./src/fatfs/ff.o \
./src/fatfs/syscall.o 

C_DEPS += \
./src/fatfs/diskio.d \
./src/fatfs/fatfs_sd_sdio.d \
./src/fatfs/ff.d \
./src/fatfs/syscall.d 


# Each subdirectory must supply rules for building sources it contributes
src/fatfs/%.o: ../src/fatfs/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -Og -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -ffreestanding -fno-move-loop-invariants -Wall -Wextra  -g3 -DDEBUG -DUSE_FULL_ASSERT -DTRACE -DOS_USE_TRACE_SEMIHOSTING_DEBUG -DSTM32F407xx -DUSE_HAL_DRIVER -DHSE_VALUE=8000000 -I"../include" -I"../system/include" -I"../system/include/cmsis" -I"../system/include/stm32f4-hal" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


