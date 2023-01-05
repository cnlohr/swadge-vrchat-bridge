all : sandbox_upload run sandbox_interactive

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
CFLAGS:=-g -O0
LDFLAGS:=-ludev
CC:=gcc
else
CFLAGS:=-Os -s
CC:=gcc
LDFLAGS:=C:/windows/system32/setupapi.dll
endif

SWADGE_ROOT:=C:/projects/Super-2023-Swadge-FW

SYSELF:=$(SWADGE_ROOT)/build/swadge-esp32.elf
#SYSELF:=../flashelf/swadge-esp32.elf

CFLAGS+=-I../lib

build : 
	mkdir -p build

sandbox.o : buildhelp sandbox.c $(SYSELF) build
	SWADGE_ROOT=$(SWADGE_ROOT) ./buildhelp $(SYSELF)
	xtensa-esp32s2-elf-objdump -s build/sandbox.o > build/debug_sandbox_s.txt
	xtensa-esp32s2-elf-objdump -t build/sandbox.o > build/debug_sandbox_t.txt
	xtensa-esp32s2-elf-objdump -S build/sandbox.o > build/debug_sandbox_S.txt

run : sandbox_upload sandbox.o
	SWADGE_ROOT=$(SWADGE_ROOT) ./sandbox_upload

buildhelp : buildhelp.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

sandbox_upload : sandbox_upload.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

sandbox_interactive : sandbox_interactive.c
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

monitor : sandbox_interactive
	SWADGE_ROOT=$(SWADGE_ROOT) ./sandbox_interactive

interactive : sandbox_interactive build
	SWADGE_ROOT=$(SWADGE_ROOT) ./sandbox_interactive sandbox.c sandbox.S $(SYSELF)

clean :
	rm -rf *.o *~ build/sandbox_inst.bin build/sandbox_data.bin build/buildhelp build/sandbox.o sandbox_upload build/sandbox.lds build/provided.lds build/sandbox_symbols.txt build/system_symbols.txt sandbox_interactive buildhelp.exe sandbox_upload.exe buildhelp build



