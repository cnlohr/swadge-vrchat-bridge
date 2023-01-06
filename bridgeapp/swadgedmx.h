#ifndef _SWADGEDMX_H
#define _SWADGEDMX_H

void SwadgeUpdateDMX( uint8_t * data, int length );


#ifdef SWADGEDMX_IMPLEMENTATION


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

og_thread_t swadgedmxthread;
og_mutex_t  swadgedmxdatamutex;
og_sema_t   swadgedmxsend;
uint8_t * swadgedmxdata;
int swadgedmxdatalen;

void * SwadgeDMXThread( void * v )
{
	int intbuflen = 0;
	uint8_t * intbuf = 0;
	hid_device * hd = 0;
	hid_init();
	
	while(1)
	{
		if( !hd )
		{
			hd = hid_open( SWADGE_VID, SWADGE_PID, L"cndmx512v001" );
		}
		else
		{
			// hd is valid.
			// First, see if we should copy the swadgedmxdata.
#ifndef FREEWHEEL_DMX_UPDATES
			OGLockSema( swadgedmxsend ); // We can remove this if we want to freewheel.
#endif
			OGLockMutex( swadgedmxdatamutex );
			if( swadgedmxdatalen )
			{
				if( intbuf ) free( intbuf );
				// Consume the DMX-512 frame
				intbuflen = swadgedmxdatalen;
				intbuf = swadgedmxdata;
				swadgedmxdata = 0;
				swadgedmxdatalen = 0;
			}
			OGUnlockMutex( swadgedmxdatamutex );

			int r;
			int tries = 0;
			int chunk;
			int chunks = (intbuflen + 247) / 248;
			for( chunk = chunks-1; chunk >= 0; chunk-- )
			{
				// Upon sending 0th chunk, it will transmit the acutal signal.
				uint8_t rdata[257] = { 0 };

				int offset = chunk * 248;
				int remain = intbuflen - offset;
				if( remain > 248 ) remain = 248;

				rdata[0] = 0xab;  // Feature Report ID
				rdata[1] = 0x73;
				rdata[2] = offset/4;
				rdata[3] = remain;
				memcpy( rdata+4, intbuf + chunk * 248, remain );
				
				//printf( "%d %d rdata[10] = %02x\n", offset, remain, rdata[15] );
				do
				{
					r = hid_send_feature_report( hd, rdata, 255 );
					if( tries++ > 10 )
					{
						fprintf( stderr, "Error sending feature report on command %d (%d)\n", rdata[1], r );
						hid_close( hd ); hd = 0;
						break;
					}
				} while ( r < 6 );
				if( !hd ) break;
				tries = 0;
			}
		}
		OGUSleep( 5 );
	}
}

void CopyColor( uint8_t * out, int poso, uint8_t * in, int posi )
{
	int oo = poso;
	int ii = posi;
	out[(oo)*3+0] = in[(ii)*3+0];
	out[(oo)*3+1] = in[(ii)*3+1];
	out[(oo)*3+2] = in[(ii)*3+2];
}

void SwadgeUpdateDMX( uint8_t * data, int length )
{
	if( !swadgedmxthread )
	{
		swadgedmxthread = OGCreateThread( SwadgeDMXThread, 0 );
		swadgedmxdatamutex = OGCreateMutex();
		#ifndef FREEWHEEL_DMX_UPDATES
		swadgedmxsend = OGCreateSema();
		#endif
	}
	
	OGLockMutex( swadgedmxdatamutex );
	if( length != swadgedmxdatalen )
	{
		swadgedmxdata = realloc( swadgedmxdata, length );
	}
	
	// Total of 168 lights.
	
	// Chacer to test.
#if 0
	static int frame;
	frame++;
	memset( data, 0, 512 );
	data[(frame%168)*3+0] = 0xff;
	data[(frame%168)*3+1] = 0xff;
	data[(frame%168)*3+2] = 0xff;
#endif

	// Adam's MAGFest setup.  This was chosen randomly and fixed in software.
	// 1         6
	// 2         5
	//   7  3  4  
	int i;
	for( i = 0; i < 24; i++ )
		CopyColor( swadgedmxdata, i, data, i );
	for( ; i < 24*2; i++ )
		CopyColor( swadgedmxdata, i, data, i );
	for( ; i < 24*3; i++ )
		CopyColor( swadgedmxdata, i, data, 24*3+(24-(i%24)-1) );
	for( ; i < 24*4; i++ )
		CopyColor( swadgedmxdata, i, data, 24*4+(i%24) );
	for( ; i < 24*5; i++ )
		CopyColor( swadgedmxdata, i, data, 24*5+(24-(i%24)-1) );
	for( ; i < 24*6; i++ )
		CopyColor( swadgedmxdata, i, data, 24*6+(i%24) );
	for( ; i < 24*7; i++ )
		CopyColor( swadgedmxdata, i, data, 24*2+(24-(i%24)-1));
	for( i=i*3; i < length; i++ )
	{
		swadgedmxdata[i] = 0;
	}
	
//	memcpy( swadgedmxdata, data, length );
	swadgedmxdatalen = length;

	#ifndef FREEWHEEL_DMX_UPDATES
	if( OGGetSema( swadgedmxsend ) < 1 )
		OGUnlockSema( swadgedmxsend );
	#endif
	OGUnlockMutex( swadgedmxdatamutex );
}


#endif

#endif