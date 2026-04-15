VITIS_INSTALL_DIR := /tools/Xilinx/Vitis/2021.2
VITIS_TOOLCHAIN := $(VITIS_INSTALL_DIR)/gnu/aarch64/lin/aarch64-none/bin/aarch64-none-elf-
CC := $(VITIS_TOOLCHAIN)gcc
AR := $(VITIS_TOOLCHAIN)ar
SIZE := $(VITIS_TOOLCHAIN)size
OBJCOPY := $(VITIS_TOOLCHAIN)objcopy

BSP_DIR := ../bsp/psu_cortexa53_0

CC_FLAGS := -MMD -MP -Wall -fmessage-length=0 -g -O0 -ggdb3 -DARMA53_64
BSP_FLAGS := -c
LN_FLAGS := -Wl,--start-group,-lxil,-lgcc,-lc,--end-group -Wl,--gc-sections

C_SOURCES := $(wildcard *.c)
S_SOURCES := $(wildcard *.S)
s_SOURCES := $(wildcard *.s)
INCLUDES := $(wildcard *.h)
OBJS := $(patsubst %.c, %.o, $(C_SOURCES))
OBJS += $(patsubst %.S, %.o, $(S_SOURCES))
OBJS += $(patsubst %.s, %.o, $(s_SOURCES))
DEPFILES := $(patsubst %.o, %.d, $(OBJS))

EXEC := gpio_led_app.elf

INCLUDEPATH := -I$(BSP_DIR)/include -I.
LIBPATH := -L$(BSP_DIR)/lib
LSCRIPT := -T$(CURDIR)/lscript.ld

.PHONY: all clean info help

all: $(EXEC)
	@echo "Build complete: $(EXEC)"
	@$(SIZE) $(EXEC)

$(EXEC): $(OBJS)
	@echo "Linking $@..."
	$(CC) -o $@ $(sort $(OBJS)) $(CC_FLAGS) $(LSCRIPT) $(LN_FLAGS) $(LIBPATH)

%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(BSP_FLAGS) $(CC_FLAGS) -c $< -o $@ $(INCLUDEPATH)

%.o: %.S
	@echo "Assembling $<..."
	$(CC) $(BSP_FLAGS) $(CC_FLAGS) -c $< -o $@ $(INCLUDEPATH)

%.o: %.s
	@echo "Assembling $<..."
	$(CC) $(BSP_FLAGS) $(CC_FLAGS) -c $< -o $@ $(INCLUDEPATH)

clean:
	@echo "Cleaning..."
	rm -rf $(OBJS) $(DEPFILES) $(EXEC) *.o *.d

info:
	@echo "=== Build Configuration ==="
	@echo "Compiler: $(CC)"
	@echo "BSP: $(BSP_DIR)"
	@echo "Linker Script: lscript.ld"
	@echo "Source: $(C_SOURCES)"

help:
	@echo "Usage: make, make clean, make info"

-include $(DEPFILES)
