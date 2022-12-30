
ifeq ($(shell uname), Linux)
CFLAGS:=-g -O2
LDFLAGS:=-lm -lpthread
TARGET:=rtmpbridge
else
CFLAGS:=-g -O2
LDFLAGS:=-lm -luser32 -lws2_32
TARGET:=rtmpbridge.exe
endif

all : $(TARGET)

   
$(TARGET) : rtmpbridge.c
	gcc $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean :
	rm -rf $(TARGET)

