################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/drivers/fatfs_sd.c \
../src/drivers/fatfs_sd_sdio.c \
../src/drivers/fatfs_sdram.c \
../src/drivers/fatfs_spi_flash.c \
../src/drivers/fatfs_usb.c 

OBJS += \
./src/drivers/fatfs_sd.o \
./src/drivers/fatfs_sd_sdio.o \
./src/drivers/fatfs_sdram.o \
./src/drivers/fatfs_spi_flash.o \
./src/drivers/fatfs_usb.o 

C_DEPS += \
./src/drivers/fatfs_sd.d \
./src/drivers/fatfs_sd_sdio.d \
./src/drivers/fatfs_sdram.d \
./src/drivers/fatfs_spi_flash.d \
./src/drivers/fatfs_usb.d 


# Each subdirectory must supply rules for building sources it contributes
src/drivers/%.o: ../src/drivers/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -mfloat-abi=soft -Og -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -ffreestanding -fno-move-loop-invariants -Wall -Wextra  -g3 -DDEBUG -DUSE_FULL_ASSERT -DTRACE -DOS_USE_TRACE_SEMIHOSTING_DEBUG -DSTM32F407xx -DUSE_HAL_DRIVER -DHSE_VALUE=8000000 -I"../include" -I"../system/include" -I"../system/include/cmsis" -I"../system/include/stm32f4-hal" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


