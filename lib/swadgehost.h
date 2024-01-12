#ifndef _SWADGEHOST_H
#define _SWADGEHOST_H


#include "hidapi.h"

#ifdef WIN32
const int swag_packet_length = 65;
#else
const int swag_packet_length = 64;
#endif

typedef hid_device swadge_t;

// Returns 0 if failed to find, otherwise, returns a handle.
hid_device * swadgehost_setup();



// To send:
//Array [170] ... data.
//		r = hid_send_feature_report( hd, rdata, reg_packet_length );
//
//		uint8_t rdata[513] = { 0 };
//		rdata[0] = 172;
//		r = hid_get_feature_report( hd, rdata, 513 );
// close: hid_close
		
#ifdef SWADGEHOST_IMPLEMENTATION

#include <stdio.h>
#include <stdint.h>

#include <sys/stat.h>

#include <time.h>

#ifndef SWADGE_VID
#define SWADGE_VID 0x303a
#define SWADGE_PID 0x4004
#endif

#ifndef HIDAPI_H__
#include "../lib/hidapi.h"
#include "../lib/hidapi.c"
#endif


#ifdef WIN32
const int chunksize = 244;
const int force_packet_length = 255;
const int reg_packet_length = 65;
#else
const int chunksize = 244;
const int force_packet_length = 255;
const int reg_packet_length = 64;
#endif



hid_device * swadgehost_setup()
{
	hid_device * hd;
	hid_init();
	return hid_open( SWADGE_VID, SWADGE_PID, L"WIFIBRIDGE" );
}
	
#endif

#endif