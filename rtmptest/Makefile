
ifeq ($(shell uname), Linux)
CFLAGS:=-g -Os
LDFLAGS:=-lm -lpthread
TARGET:=rtmpswadgetest_dummy
else
CFLAGS:=-g -Os
LDFLAGS:=-lm -luser32 -lws2_32
TARGET:=rtmpswadgetest_dummy.exe
endif

all : $(TARGET)

   
$(TARGET) : rtmpswadgetest_dummy.c
	gcc $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean :
	rm -rf $(TARGET)

