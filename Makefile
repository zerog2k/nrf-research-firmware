SDCC ?= sdcc
FLASH_SIZE_16K ?= 0
ifeq ($(FLASH_SIZE_16K), 1)
    CFLAGS = --model-large --std-sdcc99 -DFLASH_SIZE_16K
else
    CFLAGS = --model-large --std-sdcc99
endif
LDFLAGS = --xram-loc 0x8000 --xram-size 2048 --model-large
VPATH = src/
OBJS = main.rel usb.rel usb_desc.rel radio.rel


SDCC_VER := $(shell $(SDCC) -v | grep -Po "\d\.\d\.\d" | sed "s/\.//g")

all: sdcc bin/ dongle.bin

sdcc:
	@if test $(SDCC_VER) -lt 310; then echo "Please update SDCC to 3.1.0 or newer."; exit 2; fi

dongle.bin: $(OBJS)
	$(SDCC) $(LDFLAGS) $(OBJS:%=bin/%) -o bin/dongle.ihx
ifeq (, $(shell which objcopy))
	# objcopy not available, using makebin (only works for nordic bootloader)
	makebin -p bin/dongle.ihx bin/dongle.bin
else
	objcopy -I ihex bin/dongle.ihx -O binary bin/dongle.bin
	objcopy --pad-to 26622 --gap-fill 255 -I ihex bin/dongle.ihx -O binary bin/dongle.formatted.bin
	objcopy -I binary bin/dongle.formatted.bin -O ihex bin/dongle.formatted.ihx
endif

%.rel: %.c
	$(SDCC) $(CFLAGS) -c $< -o bin/$@

clean:
	rm -f bin/*

install:
	./prog/usb-flasher/usb-flash.py bin/dongle.bin

spi_install:
	./prog/teensy-flasher/python/spi-flash.py bin/dongle.bin

logitech_install:
	./prog/usb-flasher/logitech-usb-flash.py bin/dongle.formatted.bin bin/dongle.formatted.ihx

bin/:
	mkdir -p bin
