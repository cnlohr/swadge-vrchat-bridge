#if defined(WINDOWS) || defined(WIN32) || defined( _WIN32 ) || defined( WIN64 )
#include <winsock2.h>
#define MSG_NOSIGNAL      0x200
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#endif

#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h> 
#include <string.h>
#include <errno.h>
#include <stdio.h>
#include <math.h>

#define _H264FUN_H_IMPL
#include "h264fun.h"

#define _RTSPFUN_H_IMPLEMENTATION
#include "rtmpfun.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include "os_generic.h"

#define w 128
#define h 96
const int g_mbw = w / 16;
const int g_mbh = h / 16;

uint8_t dumpbuffer[w*h];

int akey = 0;

void * InputThread( void * v )
{
	while( 1 )
	{
		int c = getchar();
		if( c == 10 )
			akey = !akey;
	}
}
	
	
typedef struct  // 32 bytes.
{
    uint32_t timeOffsetOfPeerFromNow;
    uint32_t timeOfUpdate;  // In our timestamp
    uint8_t  mac[6];

    // Not valid for server.
    int16_t posAt[3];
    int8_t  velAt[3];
    int8_t  rotAt[3];    // Right now, only HPR where R = 0
    uint8_t  basePeerFlags; // If zero, don't render.  Note flags&1 has reserved meaning locally for presence..  if flags & 2, render as dead.
    uint16_t  auxPeerFlags; // If dead, is ID of boolet which killed "me"
    uint8_t  framesDead;
    uint8_t  reqColor;
} multiplayerpeer_t;

typedef struct  // Rounds up to 16 bytes.
{
    uint32_t timeOfLaunch; // In our timestamp.
    int16_t launchLocation[3];
    int16_t launchRotation[2]; // Pitch and Yaw
    uint16_t flags;  // If 0, disabled.  Otherwise, is a randomized ID.
} boolet_t;

int main()
{
	int r;
	OGCreateThread( InputThread, 0 );
	struct RTMPSession rtmp;
	{
		FILE * f = fopen( ".streamkey", "rb" );
		if( !f )
		{
			fprintf( stderr, "Error: could not open .streamkey\n" );
			return -5;
		}
		char streamkey[256] = { 0 };
		if( fscanf( f, "%255s\n", streamkey ) != 1 )
		{
			fprintf( stderr, "Error: could not parse .streamkey\n" ); 
			return -6;
		}
		fclose( f );
//ingest.vrcdn.live
//localhost
		r = InitRTMPConnection( &rtmp, 0, "rtmp://ingest.vrcdn.live/live", streamkey );
		memset( streamkey, 0, sizeof( streamkey ) );
		if( r )
		{
			return r;
		}
	}

	printf( "RTMP Server connected.\n" );

	OGUSleep( 500000 );

	H264Funzie funzie;
	{
		const H264ConfigParam params[] = { /*{H2FUN_CNT_TYPE, 2}, */{ H2FUN_TIME_ENABLE, 0 },  { H2FUN_TIME_NUMERATOR, 1000 }, { H2FUN_TIME_DENOMINATOR, 10000 }, { H2FUN_TERMINATOR, 0 } };
		r = H264FunInit( &funzie, w, h , 1, (H264FunData)RTMPSend, &rtmp, params );
		if( r )
		{
			fprintf( stderr, "Closing due to H.264 fun error.\n" );
			return r;
		}
	}

	usleep(500000);
	int frameno = 0;
	int cursor = 0;
	while( 1 )
	{
		int bk;
		frameno++;
		
		double dNow = OGGetAbsoluteTime();
		uint32_t usNow = (uint32_t)(dNow * 1000000.0);

		boolet_t boolets[(g_mbw*g_mbh-3)*8];
		boolet_t * b = boolets;
		boolet_t * bend = b + (g_mbw*g_mbh-3)*8;
		int bid = 0;
		for( ; b != bend; b++, bid++ )
		{
			int pid = bid / 4;
			b->timeOfLaunch = (usNow + 1000000*((bid&3)));
			b->launchLocation[0] = sin( pid * 0.1+ frameno*.01 ) * 1280;
			b->launchLocation[1] = pid*8+(bid&3);
			b->launchLocation[2] = cos( pid * 0.1 + frameno*.01 ) * 1280;
			b->launchRotation[0] = (pid*2)*15;
			b->launchRotation[1] = (pid*.5+frameno*.5)*15;
			b->flags = bid;
		}

		
		multiplayerpeer_t players[(g_mbw*g_mbh-3)*2];
		multiplayerpeer_t * p = players;
		multiplayerpeer_t * pend = p + (g_mbw*g_mbh-3)*2;
		int pid = 0;
		for( ; p != pend; p++, pid++ )
		{
			p->timeOffsetOfPeerFromNow = 0; // UNTRANSMITTED
			memset( p->mac, 0, sizeof( p->mac ) ); // UNTRANSMITTED
			p->framesDead = 0;               //UNTRANSMITTED

			p->timeOfUpdate = usNow-500;
			p->posAt[0] = sin( pid * 0.1 + frameno*.01 ) * 1280;
			p->posAt[1] = pid*8;
			p->posAt[2] = cos( pid * 0.1 + frameno*.01 ) * 1280;
			p->velAt[0] = 0;
			p->velAt[1] = 0;
			p->velAt[2] = 0;
			p->rotAt[0] = pid*2;
			p->rotAt[1] = pid*.5+frameno*.5;
			p->rotAt[2] = 0;
			p->basePeerFlags = 1;
			p->auxPeerFlags = 0;
			p->reqColor = pid; // Bright white.
		}
	
/*
		if( ( frameno % 200 ) == 1 )
		{
			H264FakeIFrame( &funzie );
			//H264FunEmitIFrame( &funzie );
		}
		else */
		{
			
			for( bk = 0; bk < g_mbw*g_mbh; bk++ )
			{
				int mbx = 0;
				int mby = 0;

				int basecolor = akey?254:1;
				uint8_t * buffer = malloc( 256 );
				memset( buffer, 0xff, 256 );
				#if 0
				if( bk == 0 )
				{
					mbx = mby = 0;
				}
				else
				#endif
				{
					mbx = cursor%g_mbw;
					mby = (cursor/g_mbw)%g_mbh;
					cursor++;
				}
				//mbx = bk;
				//mby = 0;

				const uint16_t font[] = //3 px wide, buffer to 4; 5 px high, buffer to 8.
				{
					0b111101101101111,
					0b010010010010010,
					0b111001111100111,
					0b111001011001111,
					0b001101111001001,
					0b111100111001111,
					0b111100111101111,
					0b111001001010010,
					0b111101111101111,
					0b111101111001001,
					0b000000000000010, //.
					0b000010000010000, //:
					0b000000000000000, // (space)
				};

				if( mbx == 2 && mby == 0 )
				{

					char towrite[100];
					int cx, cy;
					int writepos = 0;
					for( cy = 0; cy < 2; cy++ )
					for( cx = 0; cx < 4; cx++ )
					{
						uint16_t pxls = 0;
						
						int num = dNow * 100;
						int p10 = 1;
						int j;
						for( j = 3; j > cx; j-- )
							p10*=10;

						if( cy == 0 )
						{
							pxls = font[(num/p10)%10];
						}
						else if( cy == 1 )
						{
							pxls = font[(num/10000/p10)%10];
						}
						int px, py;
						for( py = 0; py < 8; py++ )
						for( px = 0; px < 4; px++ )
						{
							int color = ((pxls>>(14-(py*3-3+px)))&1)?(255-basecolor):basecolor;
							if( px == 3 ) color = basecolor;
							
							int pos = (py+cy*8)*16+px+cx*4;
						
							int rpx = px+cx*4 + mbx*16;
							int rpy = py+cy*8 + mby*16;
							buffer[pos] = color;
						}
					}
				}
				else
				{
					int color;
					int rpx, rpy;
					for( rpy = 0; rpy < 16; rpy++ )
					{
						for( rpx = 0; rpx < 16; rpx++ )
						{
							if( mbx == 0 && mby == 0)
							{
								color = rpx+rpy*16;
							}
							else if( mbx == 1 && mby == 0)  // crosshairs
							{
								if( rpy == 0 )
								{
									// Encode timestamp of "now" in top row.
									if( rpx & 0x1 )
										color = 255 - ((uint8_t)(usNow >> (((rpx&0x6)>>1)*8)));
									else
										color = usNow >> (((rpx&0x6)>>1)*8);
								}
								else if( rpy == 1 )
								{
									// Encode sentinel in second row.
									if( rpx & 0x1 )
										color = 255 - ((uint8_t)(0x5AAA0fff >> (((rpx&0x6)>>1)*8)));
									else
									{
										color = 0x5AAA0fff >> (((rpx&0x6)>>1)*8);
									}
								}
								else if( rpx >= 8 && rpy >= 8 )
								{
									const char * pattern = ""
									"00000000"
									"00000000"
									"00``0`00"
									"0`00`000"
									"00``0`00"
									"00000000"
									"00000000"
									"00000000";
									color = pattern[(rpx-8)+(rpy-8)*8];
								}
								else
								{
									int chat = rpx/8+rpy/8 + akey;
									color = (chat&1)?0xff:0x01;
								}
							}
							else
							{
								int shipid = (mbx + mby * g_mbw - 3)*2+(rpy/8);
								p = &players[shipid];
								b = &boolets[shipid*4];

								// Consider your location rpx, rpy.
								int pxINid = (rpx + rpy * 16)&0x7f;
								// Split in groups of 3.
								int pxid = pxINid * 2 / 3;

								// pxINid 0    1    2     3    4    5    6
								// pxid   0    0    1     2    2    3    4
								if( (pxINid % 3) == 1 )
								{
									color = 0xff;
								}
								else
								{
									switch( pxid )
									{
									case 0 ... 3:
										color = (p->timeOfUpdate>>(pxid*8));
										break;
									case 4 ... 9:
										color = p->posAt[(pxid-4)/2] >> ( (pxid&1) * 8 );
										break;
									case 10 ... 12:
										color = p->velAt[pxid-10];
										break;
									case 13 ... 15:
										color = p->rotAt[pxid-13];
										break;
									case 16:
										color = p->basePeerFlags;
										break;
									case 17 ... 18:
										color = p->auxPeerFlags>> ( (pxid&1) * 8 );
										break;
									case 19:
										color = p->reqColor;
										break;
									case 20 ... 35:
										color = (b+((pxid-20)/4))->timeOfLaunch >> ( (pxid&3) * 8 );
										break;
									case 36 ... 59:
										color = (b+((pxid-36)/6))->launchLocation[((pxid-36)/2)%3] >> ( (pxid&1) * 8 );
										break;
									case 60 ... 75:
										color = (b+((pxid-60)/4))->launchRotation[((pxid-60)/2)%2] >> ( (pxid&1) * 8 );
										break;
									case 76 ... 83:
										color = (b+((pxid-76)/2))->flags >> ( ( pxid & 1 ) * 8);
										break;
									case 84:
										color = 0x7f; // Present or not?
										break;
									}
								}
							}
							int pos = rpx + rpy * 16;
							buffer[pos] = color;
						}
					}
				}
				
				if( frameno == 1 )
				{
					int x, y;
					for( y = 0; y < 16; y++ )
					for( x = 0; x < 16; x++ )
					{
						int pli = (x+y*16);
						int plx = (x+mbx*16+(h-(y+mby*16)-1)*w);
						dumpbuffer[plx] = buffer[pli];
					}
				}

				H264FunAddMB( &funzie, mbx,  mby, buffer, H264FUN_PAYLOAD_LUMA_ONLY );
			}
			//H264FunEmitFrame( &funzie );
			H264FunEmitIFrame( &funzie );
			if( frameno == 1 )
			{
				stbi_write_png( "../PreUS1.0/Assets/SwadgeIntegration/dummy_payload.png", w, h, 1, dumpbuffer, w);
			}
		}
		//OGUSleep( 16000 );
		static double dly;
		double now = OGGetAbsoluteTime();
		if( dly == 0 ) dly = now;
		while( dly > now )
		{
			now = OGGetAbsoluteTime();
		}
		dly += 0.05;
	}

	return 0;
}



