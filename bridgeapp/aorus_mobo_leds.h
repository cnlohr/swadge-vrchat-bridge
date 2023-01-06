#ifndef _AORUS_MOBO_LEDS_H
#define _AORUS_MOBO_LEDS_H

// Using gigabyte Fusion.

void UpdateAORUSLEDs( uint8_t * leddata, int length );

#ifdef AORUS_MOBO_LEDS_IMPLEMENTATION

#include <stdio.h>
#include <stdint.h>
#include <sys/stat.h>
#include <time.h>

#ifndef HIDAPI_H__
#include "../lib/hidapi.h"
#include "../lib/hidapi.c"
#endif

hid_device * aorusdev;
aorusbuffer[512];
og_thread_t aorusthread;

void SetupAORUS();

int IsAORUSPresent()
{
	if( !aorusdev )
	{
		SetupAORUS();
	}
	return !!aorusdev;
}

void SetupAORUS()
{
	hid_init();
	aorusdev = hid_open_path(  "\\\\?\\hid#vid_048d&pid_8297&col02#9&3868a9be&0&0001#{4d1e55b2-f16f-11cf-88cb-001111000030}" ); //hid_open( 0x048d, 0x8297, 0 );
	if( aorusdev )
	{
		printf( "Fusion USB Motherboard detected.\n" );
	}
}

void * AORUSThreadApp( void * v )
{
	int all = 0;
	while( 1 )
	{
		if( !aorusdev )
		{
			SetupAORUS();
			if( !aorusdev )
			{
				Sleep(100);
				continue;
			}
		}
		
		// aorusdev is valid.

		uint8_t databuff[64];
		uint8_t * dptr = databuff;
		
		int cvled = 0;
		
		// LEDs on header
		int group = 0;
		int led = 0;
		for( group = 0; group < 4; group++ )
		{
			dptr = databuff;
			*(dptr++) = 0xcc;
			*(dptr++) = 0x58;
			*(dptr++) = group * 0x39;
			*(dptr++) = 0x00;
			*(dptr++) = 0x39;
		
			int i = 0;
			for( i = 0; i < 19; i++ )
			{
				*(dptr++) = (aorusbuffer[cvled]>>8)&0xff;
				*(dptr++) = (aorusbuffer[cvled]>>0)&0xff;
				*(dptr++) = (aorusbuffer[cvled]>>16)&0xff;
				if( !all ) cvled++;
			}
			*(dptr++) = 0;
			*(dptr++) = 0;
			int r = hid_send_feature_report( aorusdev, databuff, 64 );
		}

		// Mobo LEDs
		int mark = 0;
		for( mark = 0; mark < 5; mark++ )
		{
			int bv = 1<<mark;
			dptr = databuff;
			*(dptr++) = 0xcc;
			*(dptr++) = 0x20+mark;
			*(dptr++) = bv;
			*(dptr++) = 0x00;

			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x01;
			
			*(dptr++) = 0x64;
			*(dptr++) = 0x00;
			*(dptr++) = (aorusbuffer[cvled]>>16)&0xff;
			*(dptr++) = (aorusbuffer[cvled]>>8)&0xff;
			*(dptr++) = (aorusbuffer[cvled]>>0)&0xff;
			if( !all ) cvled++;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;

			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0xb0;
			*(dptr++) = 0x04;
			*(dptr++) = 0xc8;
			*(dptr++) = 0x00;
			
			*(dptr++) = 0xc8;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x00;
			*(dptr++) = 0x01;
			int r = hid_send_feature_report( aorusdev, databuff, 64 );
		}
		memset( databuff, 0, sizeof( databuff ) );
		
		dptr = databuff;
		*(dptr++) = 0xcc;
		*(dptr++) = 0x28;
		*(dptr++) = 0xff;
		*(dptr++) = 0x00;
		int r = hid_send_feature_report( aorusdev, databuff, 64 );
	}
}

void UpdateAORUSMobo( uint32_t * colorval, int vals )
{
	if( vals > sizeof( aorusbuffer ) ) return;
	if( !aorusthread )
	{
		aorusthread = OGCreateThread( AORUSThreadApp, 0 );
	}
	memcpy( aorusbuffer, colorval, vals );
	
}


#endif
#endif
