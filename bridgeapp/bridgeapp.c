#include <stdio.h>
#include <windows.h>
#include <winapi/psapi.h>
#include "os_generic.h"
#include <stdint.h>
#include <string.h>
#include <math.h>

#define MINIOSC_IMPLEMENTATION
#include "miniosc.h"

#define CNFG_IMPLEMENTATION
#define CNFGOGL
#define sqrtf sqrt
#include "rawdraw_sf.h"

#define SWADGEDMX_IMPLEMENTATION
#include "swadgedmx.h"

#define CAPWIDTH 64
#define MAX_BADDIES 48
#define DATAHEIGHT (608+(MAX_BADDIES))

#define AORUS_MOBO_LEDS_IMPLEMENTATION
#include "aorus_mobo_leds.h"

#define SWADGEHOST_IMPLEMENTATION
#include "../lib/swadgehost.h"

#include "packagingfunctions.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"


#define IS_MOBILE_CART 1

int demomode = 1;
swadge_t * swadge;

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

typedef struct
{
    uint32_t timeOfUpdate;
    uint32_t binencprop;      //Encoding starts at lsb.  First: # of bones, then the way the bones are interconnected.
    int16_t root[3];
    uint8_t  radius;
    uint8_t  reqColor;
    int8_t  velocity[3];
    int8_t  bones[0*3];  //Does not need to be all that long.
} network_model_t;

og_mutex_t HidMutex;

#define MAX_BADDIES 48
float enemyPosAndProp[MAX_BADDIES][4];
float enemyRotation[MAX_BADDIES][4];


#define MAX_RTMP_PLAYERS 90
multiplayerpeer_t gOplayers[(MAX_RTMP_PLAYERS)];
boolet_t gOboolets[(MAX_RTMP_PLAYERS)*4+240];
og_mutex_t rtmpOutLock;
void * RTMPTransmitThread( void * v );
void * SwadgeReceiver( void * v );

#include "bridgeapp_rtmp.c"

HWND wnd = 0;
HDC screen;
HDC target;
HBITMAP bmp;
uint32_t * bmpBuffer;
uint32_t width;
uint32_t height;
int offset_x, offset_y;
miniosc * osc;
float fSendTimeMS;

void HandleKey( int keycode, int bDown ){ if( keycode == ' ' && bDown ) akey = !akey; }
void HandleButton( int x, int y, int button, int bDown ) { }
void HandleMotion( int x, int y, int mask ) { }
void HandleDestroy() { }
const char * mycasestr( const char * haystack, const char * needle );
BOOL CALLBACK EnumWindowsProc( HWND hwnd, LONG lParam );
int is_real_vrchat_window;

#define MAX_VRC_PLAYERS 84

og_mutex_t mutSendDataBank;
float BonePositions[MAX_VRC_PLAYERS][12][3];
#define MAX_GUNS 24
network_model_t * modGuns[MAX_GUNS];
int   LastSendPlayerPos;
int   LastGunSendPos;
int   LastBooletSendPos;
int   LastEnemySendPos;

int IsVec3Zero( float * vec )
{
	float sum = vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2];
	return sum < 0.005;
}

void SendPacketToSwadge()
{
	unsigned char data[512] = { 0 };
	data[0] = 173;

	static int iter;
	iter++;
	int i, j;
	uint8_t buff[512];
	uint8_t * pack = buff;
	uint32_t now = (uint32_t)(OGGetAbsoluteTime() * 1000000);
	int seed = now;

	*((uint32_t*)pack) = FSNET_CODE_SERVER;  pack += 4;

	OGLockMutex( mutSendDataBank );

	*((uint32_t*)pack) = now;  pack += 4;
	
	uint32_t * assetCountsPlace = (uint32_t*)pack; 	pack += 4;

	int sendmod = 0;
	int sendshp = 0;
	int sendboo = 0;
	
	static int send_no;
	send_no++;
	
	for( i = 0; i < 84; i++ )
	{
//og_mutex_t mutSendDataBank;
//float BonePositions[84][12][3];
//int   LastSendPlayerPos;

		const int force_players_on = 0;
		
		if( force_players_on || !IsVec3Zero( BonePositions[LastSendPlayerPos][0] ) )
		{
			int hasSkeleton = 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][1] ) && 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][2] ) && 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][3] ) && 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][4] ) && 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][5] ) && 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][6] ) && 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][7] ) && 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][8] ) && 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][9] ) && 
				!IsVec3Zero( BonePositions[LastSendPlayerPos][10] );
			/*
				BoneData[place++] = p.GetPosition();  //0
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.Head); // 1
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.Neck); //2
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftLowerLeg); //3
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightLowerLeg); //4
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftFoot); //5
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightFoot); //6
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftLowerArm); //7
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightLowerArm); //8
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftHand); //9
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightHand); //10
				*/
			sendmod++;
			hasSkeleton |= force_players_on;
			int nrbones = hasSkeleton?12:1;

			// First is a codeword.  Contains ID, bones, bone mapping.
			uint32_t codeword = ((LastSendPlayerPos)) | ((nrbones-1)<<8);

			int sbl = 4+8;
			
			if( hasSkeleton )
			{
				/*
				codeword |= 1 << (sbl++); // To Neck
				codeword |= 1 << (sbl++); // To Left-Forearm
				codeword |= 1 << (sbl++); // To Left-Hand
				codeword |= 0 << (sbl++);  // 0 is yes, reset back to zero.
				codeword |= 0 << (sbl++);  // ---> Go back to Neck
				codeword |= 1 << (sbl++); // To Right-Forearm
				codeword |= 1 << (sbl++); // To Right-Hand
				//?? Extra 1?
				codeword |= 0 << (sbl++);  // 0 is yes, reset back to zero.
				codeword |= 0 << (sbl++);  // ---> Go back to Neck
				codeword |= 1 << (sbl++); // To Head
				codeword |= 0 << (sbl++);  // 0 is yes, reset back to zero.
				codeword |= 1 << (sbl++); // Go to left leg. (AND DRAW)
				codeword |= 1 << (sbl++); // Go to left foot.
				codeword |= 0 << (sbl++);  // 0 is yes, reset back to zero.
				codeword |= 1 << (sbl++); // Go to right leg. (AND DRAW)
				codeword |= 1 << (sbl++); // Go to right foot.
				*/
				// Above generates the following:
				codeword |= 0b1011001100110111<<sbl; sbl+=16;
					//0b1100110011100111<<sbl; sbl+=16;  //WORKS, right leg
			}
			else
			{
				// Just one bone, we're a pointy boi.
				codeword |= 1 << (sbl++);
			}
			
			
			/*
				BoneData[place++] = p.GetPosition();                                    0
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.Head);             1
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.Neck);             2
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftLowerLeg);     3
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightLowerLeg);    4
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftFoot);         5
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightFoot);        6
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftLowerArm);     7
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightLowerArm);    8
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.LeftHand);         9
				BoneData[place++] = p.GetBonePosition(HumanBodyBones.RightHand);       10
				BoneData[place++] = p.GetVelocity();
			*/
			
			*((uint32_t*)pack) = codeword; pack += 4;

			int16_t loc[3];
			int ang = ((now >> 19)+i*30) % 360;
			loc[0] = -BonePositions[LastSendPlayerPos][0][0] * 64; // XXX UNIVERSE FLIP
			loc[1] = BonePositions[LastSendPlayerPos][0][1] * 64;
			loc[2] = BonePositions[LastSendPlayerPos][0][2] * 64;
			memcpy( pack, loc, sizeof( loc ) ); pack += sizeof( loc );
			*(pack++) = 255; // radius
			*(pack++) = 35; // req color
			int8_t vel[3];
			vel[0] = -BonePositions[LastSendPlayerPos][11][0] * 4; // XXX UNIVERSE FLIP
			vel[1] = BonePositions[LastSendPlayerPos][11][1] * 4;
			vel[2] = BonePositions[LastSendPlayerPos][11][2] * 4;
			memcpy( pack, vel, sizeof( vel ) ); pack += sizeof( vel );

			int16_t cursor[3];
			memcpy( cursor, loc, sizeof( cursor ) );

			if( hasSkeleton )
			{
				const int boneAssignments[14] = { 2, 7, 9, 2, 8, 10, -999, 3, 5, -999, 4, 6, 2, 1 };
				for( j = 0; j < sizeof(boneAssignments)/sizeof(boneAssignments[0]); j++ )
				{
					int emitBone = boneAssignments[j];
					int16_t newp[3];
					if( emitBone < 0 )
					{
						emitBone *= -1;
						if( emitBone == 999 )
						{
							memcpy( cursor, loc, sizeof( cursor ) );
							continue;							
						}
						else
						{
							newp[0] = -BonePositions[LastSendPlayerPos][emitBone][0] * 64; // XXX UNIVERSE FLIP
							newp[1] = BonePositions[LastSendPlayerPos][emitBone][1] * 64;
							newp[2] = BonePositions[LastSendPlayerPos][emitBone][2] * 64;

							newp[0] = newp[0];
							newp[1] = newp[1];
							newp[2] = newp[2];
						}
					}
					else
					{
						newp[0] = -BonePositions[LastSendPlayerPos][emitBone][0] * 64; // XXX UNIVERSE FLIP
						newp[1] = BonePositions[LastSendPlayerPos][emitBone][1] * 64;
						newp[2] = BonePositions[LastSendPlayerPos][emitBone][2] * 64;
					}

					((int8_t*)pack)[0] = newp[0] - cursor[0];
					((int8_t*)pack)[1] = newp[1] - cursor[1];
					((int8_t*)pack)[2] = newp[2] - cursor[2];
					
					if( emitBone == 1 )
					{
						//TRICKY: Make heads look bigger.  Otherwise it looks jankey.
						((int8_t*)pack)[0] *= 2;
						((int8_t*)pack)[1] *= 2;
						((int8_t*)pack)[2] *= 2;
					}
					cursor[0] = newp[0];
					cursor[1] = newp[1];
					cursor[2] = newp[2];
					pack += 3;
				}
			}
			else
			{
				int8_t bone[3];
				bone[0] = 0;
				bone[1] = 100;
				bone[2] = 0;
				memcpy( pack, bone, sizeof( bone ) ); pack += sizeof( bone );
			}
		}
		LastSendPlayerPos++;
		if(LastSendPlayerPos == MAX_VRC_PLAYERS ) LastSendPlayerPos = 0;
		if( sendmod >= 2 ) break; // Set max # of players/models to send per frame.
	}
	
	for( i = 0; i < sizeof(modGuns) / sizeof(modGuns[0] ); i++ )
	{
		// Guns
		network_model_t * g = modGuns[LastGunSendPos];
		int has_pos = ( g->root[0] || g->root[1] || g->root[2] );
		int has_dir = ( g->bones[0] || g->bones[1] || g->bones[2] );
		if( has_pos && has_dir && g->radius )
		{
			*((uint32_t*)pack) = g->binencprop; pack += 4;
			memcpy( pack, g->root, sizeof( g->root ) ); pack += sizeof( g->root );
			*(pack++) = g->radius;
			*(pack++) = g->reqColor;
			memcpy( pack, g->velocity, sizeof( g->velocity ) ); pack += sizeof( g->velocity );
			memcpy( pack, g->bones, 3 ); pack += 3;
			sendmod++;
		}

		LastGunSendPos++;
		if( LastGunSendPos == sizeof(modGuns) / sizeof(modGuns[0] ) ) LastGunSendPos = 0;
		if( sendmod >= 3 ) break;
	}

	for( i = 0; i < MAX_BADDIES; i++ )
	{
		float * epos = enemyPosAndProp[LastEnemySendPos];
		float * rot = enemyRotation[LastEnemySendPos];
		int radius = 255;
		int reqColor = 5*36;
		int8_t velocity[3] = { 0, 0, 0 };
		int16_t root[3] = { epos[0] * 64, epos[1] * 64, epos[2] * 64 };
		
		#define BNRBONES 3
		static float vertices[BNRBONES*3] = {
			-0.700000, -0.197415, -0.392405,
			0.000000, -0.197415, 1.072363,
			0.700000, -0.197415, -0.392405,
			//-0.700000, -0.197415, -0.392405,
			//0.000000, 0.462382, -0.054505,
			//0.700000, -0.197415, -0.392405,
		};
		static int8_t bones[BNRBONES*3];
		static int did_setup_bones;
		if( !did_setup_bones )
		{
			int i;
			for( i = 0; i < BNRBONES*3; i++ )
			{
				//XXX HACK: Just 1.5x arbitraraily scaled to make bigger.
				bones[i] = vertices[i]*1.5*16;
			}
			did_setup_bones = 1;
		}

		uint32_t binencprop = 
			(LastEnemySendPos + MAX_VRC_PLAYERS + MAX_GUNS) |
			(( BNRBONES-1 )<<8);

		binencprop |= 0b11<<12; // Who knows.  yolo.
		
		if( epos[3] >= 0 )
		{
			*((uint32_t*)pack) = binencprop; pack += 4;
			memcpy( pack, root, sizeof( root ) ); pack += sizeof( root );
			*(pack++) = radius;
			*(pack++) = reqColor;
			memcpy( pack, velocity, sizeof( velocity ) ); pack += sizeof( velocity );
			memcpy( pack, bones, sizeof(bones) ); pack += sizeof(bones);
			sendmod++;
		}

		LastEnemySendPos++;
		if( LastEnemySendPos == MAX_BADDIES ) LastEnemySendPos = 0;
		if( sendmod >= 5 ) break;
	}

	for( i = (MAX_RTMP_PLAYERS)*4; i < sizeof(gOboolets) / sizeof(gOboolets[0] ); i++ )
	{
		// Boolets
		boolet_t * b = gOboolets + LastBooletSendPos;
		if( pack-buff > 240 ) break; /// XXX SHIM: Disable boolets for now
		int8_t zdir[3] = { 10, 0, 0 };

		if( b->flags )
		{
			sendboo++;
			*(pack++) = LastBooletSendPos-(MAX_RTMP_PLAYERS)*4; // Local "bulletID"
			memcpy( pack, &b->timeOfLaunch, sizeof( b->timeOfLaunch ) ); pack += sizeof( b->timeOfLaunch );
			memcpy( pack, b->launchLocation, sizeof( b->launchLocation) ); pack += sizeof( b->launchLocation );
			memcpy( pack, b->launchRotation, sizeof( b->launchRotation) ); pack += sizeof( b->launchRotation );
			memcpy( pack, &b->flags, sizeof(b->flags) ); pack += sizeof( b->flags );
		}
		else
		{
			sendboo++;
			*(pack++) = 0;//LastBooletSendPos-(MAX_RTMP_PLAYERS)*4; // Local "bulletID"
			memset( pack, 0, sizeof( b->timeOfLaunch ) ); pack += sizeof( b->timeOfLaunch );
			memset( pack, 0, sizeof( b->launchLocation) ); pack += sizeof( b->launchLocation );
			memcpy( pack, zdir, sizeof( b->launchRotation) ); pack += sizeof( b->launchRotation );
			memset( pack, 0, sizeof(b->flags) ); pack += sizeof( b->flags );
		}
		
		LastBooletSendPos++;
		if( LastBooletSendPos == sizeof(gOboolets) / sizeof(gOboolets[0] ) ) LastBooletSendPos = (MAX_RTMP_PLAYERS)*4;
		if( sendboo >= 3 ) break;
	}
	

#if 0
	// Now, need to send boolets.
	for( i = 0; i < 5; i++ )
	{
		sendboo++;
		
		int16_t loc[3];
		int16_t rot[2] = { 0 };
		rot[1] = 1000;
		uint16_t bid = i+1 +send_no;

		int ang = (i*30+(now >> 12)) % 360;
		loc[0] = i;//getSin1024( ang )>>3;
		loc[1] = 500;
		loc[2] = 0;//getCos1024( ang )>>3;

		*(pack++) = i+send_no; // Local "bulletID"
		memcpy( pack, &now, sizeof(now) ); pack += sizeof( now );
		memcpy( pack, loc, sizeof(loc) ); pack += sizeof( loc );
		memcpy( pack, rot, sizeof(rot) ); pack += sizeof( rot );
		memcpy( pack, &bid, sizeof(bid) ); pack += sizeof( bid );
	}
#endif


#if 0
	// DEMO SHIPS
	for( i = 0; i < 3; i++ )
	{
		sendshp++;
		
		// Send a ship.
		*(pack++) = i+send_no; // "shipNo"
		int16_t loc[3];
		int ang = ((now >> 12)+i*30) % 360;
		loc[0] = speedyHash( seed ) >> 6; //getSin1024( ang )>>3;
		loc[1] = speedyHash( seed ) >> 6;//200;
		loc[2] = speedyHash( seed ) >> 6;//getCos1024( ang )>>3;
		int8_t vel[3] = { 0 };
		int8_t orot[3] = { 0 };
		memcpy( pack, loc, sizeof( loc ) ); pack += sizeof( loc );
		memcpy( pack, vel, sizeof( vel ) ); pack += sizeof( vel ); //mirrors velAt real speed = ( this * microsecond >> 16 )
		orot[0] = ((now>>16)&0xff);
		orot[1] = 0;
		orot[2] = 0;
		memcpy( pack, orot, sizeof( orot ) ); pack += sizeof( orot );

		uint8_t flags = 1;
		uint16_t kbb = 0;
		memcpy( pack, &flags, sizeof( flags ) ); pack += sizeof( flags );
		memcpy( pack, &kbb, sizeof( kbb ) ); pack += sizeof( kbb );
		*(pack++) = (i+send_no+iter*10)%216; // req color
	}
	#endif
	
	
	OGUnlockMutex( mutSendDataBank );
	//printf( "PL: %d %d\n", pack - buff, now );

	
	uint32_t assetCounts = 0;
	int acbits = 0;

	acbits += WriteUEQ( &assetCounts, 1 );
	acbits += WriteUEQ( &assetCounts, sendmod ); //models
	acbits += WriteUEQ( &assetCounts, sendshp ); // ships
	acbits += WriteUEQ( &assetCounts, sendboo ); // boolet
	acbits += WriteUEQ( &assetCounts, 0 ); // No cursed oopseys text
	acbits += WriteUEQ( &assetCounts, 0 ); // No cursed regular text
	acbits += WriteUQ( &assetCounts, 1, 1 );
	FinalizeUEQ( &assetCounts, acbits );
	*assetCountsPlace = assetCounts;

	int len = pack - buff;
	if( len < 254 )
	{
		data[1] = len;
		memcpy( data+2, buff, len );
		double Start = OGGetAbsoluteTime();
		int r = hid_send_feature_report( swadge, data, 257 );
		fSendTimeMS = (r>=0)?( (OGGetAbsoluteTime()-Start) * 1000):-1;
	}
	else
	{
		printf( "SWADGE PACKET OVERFLOW %d\n", len );
	}
}


void * SwadgeSender( void * v )
{
	while( 1 )
	{
		OGLockMutex( HidMutex );
		if( swadge )	
			SendPacketToSwadge();
		OGUnlockMutex( HidMutex );
		Sleep(1);
	}
}

void SwadgeSetup()
{
	HidMutex = OGCreateMutex();
	OGCreateThread( SwadgeSender, 0 );
	OGCreateThread( SwadgeReceiver, 0 );
}

void ComputeRGBs( int ox, int oy, int classic, int twopole, int doaorus )
{
	uint8_t dmx512[512];
	int l;
#if 0
	// Really basic colorchord.
	int max_lin_leds = 128;
	int l;
	for( l = 0; l < 128; l++ )
	{
		int lx = (l%2)+2;
		int ly = l/2 + 184;
		uint32_t bb = bmpBuffer[width*(DATAHEIGHT-ly+oy-1)+lx+ox];
		dmx512[l*3+0] = bb >> 16;
		dmx512[l*3+1] = bb >> 8;
		dmx512[l*3+2] = bb >> 0;
	}
	for( ; l < sizeof( dmx512 ) / 3; l++ )
	{
		int tid = l - 128;
		int lx = (tid%2)+0;
		int ly = tid/2 + 184;
		uint32_t bb = bmpBuffer[width*(DATAHEIGHT-ly+oy-1)+lx+ox];
		dmx512[l*3+0] = bb >> 16;
		dmx512[l*3+1] = bb >> 8;
		dmx512[l*3+2] = bb >> 0;
	}
#endif
	//int classic = 0;  //If 0 uses autocorr
	//int twopole = 0;
	int nrl = twopole?24:84;
	for( l = 0; l < nrl; l++ )
	{
		int cccell = (l / (float)(nrl))*128;

		int lx = (cccell% 2) + 2;
		int ly = cccell/2 + 184;
		uint32_t bb = bmpBuffer[width*(DATAHEIGHT-ly+oy-1)+lx+ox];
		int r = (bb>>16)&0xff;
		int g = (bb>>8)&0xff;
		int b = (bb>>0)&0xff;

		int tl = nrl - l; //asymmetric (84-83) = 1.
		
		
		float bbm  = 1.0;
		if( classic )
		{
			int ccsamp = twopole?(tl*2):tl;
			lx = (ccsamp % 2) + 4;
			ly = ccsamp/2 + 184;
			uint32_t b01 = bmpBuffer[width*(DATAHEIGHT-ly+oy-1)+lx+ox];
			lx = (ccsamp % 2) + 6;
			ly = ccsamp/2 + 184;
			uint32_t b23 = bmpBuffer[width*(DATAHEIGHT-ly+oy-1)+lx+ox];
			
			int b0 = (b01 >> 16)&0xff;
			int b1 = (b01 >> 8 )&0xff;
			int b2 = (b23 >> 16)&0xff;
			int b3 = (b23 >> 8 )&0xff;
			
			//printf( "%d %d %d %d %d\n", l, b0, b1, b2, b3 );
			
			bbm = ( b0 + b1 + b2 + b3 + 8 ) / 800.0;
		} else {
			int ccsamp = twopole?(tl*3):tl;

			lx = (ccsamp % 2) + 8;
			ly = ccsamp/2 + 184;
			uint32_t b01 = bmpBuffer[width*(DATAHEIGHT-ly+oy-1)+lx+ox];
			
			int b0 = (b01 >> 16)&0xff;
			int b1 = (b01 >> 8 )&0xff;
			//printf( "%d %d %d %d %d\n", l, b0, b1, b2, b3 );
			
			bbm = ( b0 + b1 + 8 ) / 500.0;							
		}

		r *= bbm;
		g *= bbm;
		b *= bbm;
		
		if( r < 0 ) r = 0; if( r > 255 ) r = 255;
		if( g < 0 ) g = 0; if( g > 255 ) g = 255;
		if( b < 0 ) b = 0; if( b > 255 ) b = 255;
		
		dmx512[l*3+0] = r;
		dmx512[l*3+1] = g;
		dmx512[l*3+2] = b;
		if( twopole )
		{
			dmx512[72+l*3+0] = r;
			dmx512[72+l*3+1] = g;
			dmx512[72+l*3+2] = b;
		}
		else if( doaorus )
		{
		}
		else
		{
			dmx512[501-l*3+0] = r;
			dmx512[501-l*3+1] = g;
			dmx512[501-l*3+2] = b;
		}
	}
	static int frame;
	frame++;
	//for( l = 0; l < 512; l++ ) dmx512[l] = frame;
	if( doaorus )
	{

		uint32_t aorusin[72*4] = { 0 };
		int i;
		for( i = 0; i < 72; i++ )
		{
			aorusin[i] = ( dmx512[i*3+0] << 0) | 
				( dmx512[i*3+1] << 8 ) |
				( dmx512[i*3+2] << 16 );
		}
		UpdateAORUSMobo( aorusin, 72*4 );
	}
	else
	{
		SwadgeUpdateDMX( dmx512, sizeof( dmx512 ) );
	}
}


int main( int argc, char ** argv )
{
	char cts[256];
	
	int i;
	for( i = 0; i < MAX_GUNS; i++ )
	{
		modGuns[i] = malloc( sizeof( network_model_t ) + 3 );
	}

	
	osc = minioscInit( 0, 9993, "127.0.0.1", 0 );

	OGCreateThread( RTMPTransmitThread, 0 );

	CNFGSetup( argv[0], 480, 890);
	SwadgeSetup();

	float dataf[DATAHEIGHT][3][3];
	uint32_t datai[DATAHEIGHT][3][3];
	uint32_t datapix[DATAHEIGHT][3*4];

	double LastGameTime = 0;
	double DeltaGameTime;
	while(1)
	{
		short w, h;
		double st = OGGetAbsoluteTime();
		CNFGClearFrame();
		CNFGHandleInput();
		CNFGGetDimensions( &w, &h );
		CNFGColor( 0xffffffff );
		
		if( wnd )
		{
			
			// Normal code
			SelectObject(target, bmp);
			PrintWindow( wnd, target, 2 );

			BITMAPINFO bminfo;
			bminfo.bmiHeader.biBitCount = 32;
			bminfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
			bminfo.bmiHeader.biCompression = BI_RGB;//BI_BITFIELDS;
			bminfo.bmiHeader.biPlanes = 1;
			bminfo.bmiHeader.biWidth = width;
			bminfo.bmiHeader.biHeight = height;
			bminfo.bmiHeader.biSizeImage = width * 4 * height; // must be DWORD aligned
			bminfo.bmiHeader.biXPelsPerMeter = 0;
			bminfo.bmiHeader.biYPelsPerMeter = 0;
			bminfo.bmiHeader.biClrUsed = 0;
			bminfo.bmiHeader.biClrImportant = 0;
			bmpBuffer = realloc(bmpBuffer, bminfo.bmiHeader.biSizeImage);
			int r = GetDIBits(target, bmp, 0, height, bmpBuffer, &bminfo, DIB_RGB_COLORS);

			// Debug: Just output
			if( 0 ) 
			{
				printf( "xWND: %d %d %d // %d\n", wnd, width, height, r );
				// Update for output.
				int i;
				for( i = 0; i < width*height; i++ )
				{
					uint32_t k = bmpBuffer[i];
					bmpBuffer[i] = ((k&0x0000ff)<<8) | ((k&0x00ff00)<<8) | ((k&0xff0000)<<8) | 0xff;
				}

				// Display what we say.
				CNFGUpdateScreenWithBitmap( bmpBuffer, width, height );
				CNFGSwapBuffers();
				Sleep(1);
				continue;
			}

			if( r != height )
			{
				printf( "R/H: %d %d\n", r, height );
				if( bmp ) DeleteObject( bmp );
				if( target ) ReleaseDC( wnd, target );
				wnd = 0;
				goto final;
			}
			int i;

			//stbi_write_png( "ttype.png", width, height, 4, bmpBuffer, width*4);

			
			int recheck = 0;
			int ox, oy;
			int x, y;
			for( y = 0; y < height-DATAHEIGHT+2; y++ )
			for( x = 0; x < width-8; x++ )
			{
				if( y == 0 )
				{
					ox = offset_x;
					oy = offset_y;
				}
				else
				{
					ox = x;
					oy = y-1;offset_x = ox;
					offset_y = oy;
				}
				
				uint32_t dataithis[1][3];
				memset( dataithis, 0, sizeof( dataithis ) );

				//for( i = 0; i < 1; i++ )
				i = DATAHEIGHT-1;
				{
					int j;
					for( j = 0; j < 4; j++ )
					{
						uint32_t col = bmpBuffer[width*(i+oy)+j+ox];
						//datapix[DATAHEIGHT-i-1][j] = col;
						uint32_t r = (col>>16)&0xff;
						uint32_t g = (col>>8)&0xff;
						uint32_t b = (col)&0xff;
						dataithis[DATAHEIGHT-i-1][0] |= r<<(j*8);
						dataithis[DATAHEIGHT-i-1][1] |= g<<(j*8);
						dataithis[DATAHEIGHT-i-1][2] |= b<<(j*8);
					}
				}
				// If we've been found (we usually hit this the first time through the loop.
				if( dataithis[0][0] == 0xaaaaaaaa && dataithis[0][1] == 0xa5a5a5a5 && dataithis[0][2] == 0x5a5a5a5a )
				{
					goto found;
				}
			}
			CNFGPenX = width+1; CNFGPenY = 0;
			CNFGDrawText( "Could not find data.", 2 );
			goto final;
		found:
			memset( datai, 0, sizeof( datai ) );

			for( i = 0; i < DATAHEIGHT; i++ )
			{
				int j;
				int xchunk;
				for( xchunk = 0; xchunk < 3; xchunk++ )
				{
					for( j = 0; j < 4; j++ )
					{
						uint32_t col = bmpBuffer[width*(i+oy)+j+ox+xchunk*4];
						datapix[DATAHEIGHT-i-1][j+xchunk*4] = col;
						uint32_t r = (col>>16)&0xff;
						uint32_t g = (col>>8)&0xff;
						uint32_t b = (col)&0xff;
						datai[DATAHEIGHT-i-1][xchunk][0] |= r<<(j*8);
						datai[DATAHEIGHT-i-1][xchunk][1] |= g<<(j*8);
						datai[DATAHEIGHT-i-1][xchunk][2] |= b<<(j*8);
					}
				}
			}

			memcpy( dataf, datai, sizeof( datai ) );
			CNFGColor( 0xffffffff );
			CNFGPenX = width+1; CNFGPenY = 0;
			sprintf( cts, "%08x %08x %08x %08x\n", datai[0][0][0], datai[0][0][1], datai[0][0][2], datai[0][0][3] );
			CNFGDrawText( cts, 2 );

			for( x = 0; x < 24; x++ )
			{
				// TODO: Use ColorChord Colors.
				int y = 1;
				CNFGPenX = width+1; CNFGPenY = 300 + x * 10;
				uint32_t k = bmpBuffer[width*(DATAHEIGHT-y+oy-1)+x+ox];
				CNFGColor( (k<<8) | 0xff );
				CNFGTackRectangle( CNFGPenX, CNFGPenY, CNFGPenX+10, CNFGPenY+10 );
			}
			
			// Interface Object position.
			for( y = 2; y < 6; y++ )
			{
				CNFGColor( 0xffffffff );
				CNFGPenX = width+1; CNFGPenY = (y-1) * 12;
				sprintf( cts, "%f %f %f\n", dataf[y][0][0], dataf[y][0][1], dataf[y][0][2] );
				CNFGDrawText( cts, 2 );
			}

			DeltaGameTime = dataf[4][0][1] - LastGameTime;
			LastGameTime = dataf[4][0][1];

			if( DeltaGameTime > 0 )
			{
				OGLockMutex( mutSendDataBank );
				
				// Player position.
				
				// Boolets
				for( y = 8; y < 184; y++ )
				{
					int bid = (y - 8)+(MAX_RTMP_PLAYERS)*4;
					int enabled = dataf[y][2][0];
					int id = dataf[y][2][1];
					if( gOboolets[bid].flags != id )
					{
						boolet_t * b = gOboolets + bid;

						b->timeOfLaunch = (uint32_t)(OGGetAbsoluteTime() * 1000000) + 80000; //Add 80ms Offset.
						b->launchLocation[0] = -dataf[y][0][0] * 64;
						b->launchLocation[1] = dataf[y][0][1] * 64;
						b->launchLocation[2] = dataf[y][0][2] * 64;
						
						// Figure out the pitch/yaw of the shot.
						float dX = -dataf[y][1][0];
						float dY = dataf[y][1][1];
						float dZ = dataf[y][1][2];

						float tau = atan2( dX, dZ );
						float mR  = sqrt( dX * dX + dZ * dZ );
						float gam = -atan2( dY, mR );
						
						b->launchRotation[0] = tau * 3920 / 6.2831852;
						b->launchRotation[1] = gam * 3920 / 6.2831852;
						b->flags = id;

						if( b->launchRotation[0] < 0 ) b->launchRotation[0] += 3920;
						if( b->launchRotation[1] < 0 ) b->launchRotation[1] += 3920;
						//printf( "%d %d %d // %d %d\n", b->launchLocation[0], b->launchLocation[1], b->launchLocation[2], b->launchRotation[0], b->launchRotation[1], b->flags );
					}
				}
				
				{
					ComputeRGBs( ox, oy, IS_MOBILE_CART, IS_MOBILE_CART, 0 ); // classic/twopole/aorus
					
					static int checked_aorus;
					static int aorus_present;
					if( !checked_aorus )
					{
						aorus_present = IsAORUSPresent();
					}
					if( aorus_present )
					{
						ComputeRGBs( ox, oy, IS_MOBILE_CART, 0, 1 ); // classic/twopole/aorus
					}
				}
				for( y = 248; y < 584; y++ )
				{
					if( y < 248+10 )
					{
						CNFGColor( 0xffffffff );
						CNFGPenX = width+1; CNFGPenY = (y-248+10) * 12;
						sprintf( cts, "%f %f %f\n", dataf[y][0][0], dataf[y][0][1], dataf[y][0][2] );
						CNFGDrawText( cts, 2 );
					}
					int playerid = (y - 248)/4;
					int field;
					
					for( field = 0; field < 3; field++ )
					{
						int fieldno = field + ((y - 248)&3)*3;
						BonePositions[playerid][fieldno][0] = dataf[y][field][0];
						BonePositions[playerid][fieldno][1] = dataf[y][field][1];
						BonePositions[playerid][fieldno][2] = dataf[y][field][2];
					}
				}

				for( y = 584; y < 608; y++ )
				{
					int gid = y - 584;
					network_model_t * g = modGuns[gid];				
					g->timeOfUpdate = (uint32_t)(OGGetAbsoluteTime() * 1000000);

					g->root[0] = -dataf[y][0][0] * 64;
					g->root[1] = dataf[y][0][1] * 64;
					g->root[2] = dataf[y][0][2] * 64;

					g->bones[0] = ( dataf[y][1][0] )* 16;
					g->bones[1] = -( dataf[y][1][1] ) * 16;
					g->bones[2] = -( dataf[y][1][2] ) * 16;
					
					g->binencprop = (gid + MAX_VRC_PLAYERS) | ( 0<<8 ) | ( 0b11<<12 ); 
					g->radius = 64;
					g->reqColor = 180; // red
					g->velocity[0] = 0;
					g->velocity[1] = 0;
					g->velocity[2] = 0;
				}
				
				for( y = 608; y < 608+48; y++ )
				{
					int e = y - 608;
					enemyPosAndProp[e][0] = dataf[y][0][0];
					enemyPosAndProp[e][1] = dataf[y][0][1];
					enemyPosAndProp[e][2] = dataf[y][0][2];
					enemyPosAndProp[e][3] = dataf[y][2][0];
					enemyRotation[e][0] = dataf[y][1][0];
					enemyRotation[e][1] = dataf[y][1][1];
					enemyRotation[e][2] = dataf[y][1][2];
					enemyRotation[e][3] = dataf[y][2][1];
				}

				printf( "E: %f %f %f %f  %f %f %f %f\n", enemyPosAndProp[0][0], enemyPosAndProp[0][1], enemyPosAndProp[0][2], enemyPosAndProp[0][3], enemyRotation[1][0], enemyRotation[1][1], enemyRotation[1][2] );
				printf( "E: %f %f %f\n", gOboolets[8].launchLocation[0], gOboolets[8].launchLocation[1], gOboolets[8].launchLocation[2] );
		
				OGUnlockMutex( mutSendDataBank );
			}

			
			// Now, get to the heart of it.  The poses.
#if 0
			for( i = 1; i < 16; i++ )
			{
				int red = dataf[i][0]*255;
				int grn = dataf[i][1]*255;
				int blu = dataf[i][2]*255;
				if( red < 0 ) red = 0; if( red > 255 ) red = 255;
				if( grn < 0 ) grn = 0; if( grn > 255 ) grn = 255;
				if( blu < 0 ) blu = 0; if( blu > 255 ) blu = 255;
				uint32_t k = (((uint32_t)red)<<24) | (grn<<16) | (blu<<8) | 0xff;

				CNFGPenX = width+1; CNFGPenY = 20 + i*10;
				if( i == 5 )
				{
					// Gradient Ramp
					sprintf( cts, "%02x %02x %02x %02x %02x %02x %02x %02x\n",
						datapix[i][0] >>16&0xff, datapix[i][1] >>16&0xff, datapix[i][2] >>16&0xff, datapix[i][3] >>16&0xff,
						datapix[i][4] >>16&0xff, datapix[i][5] >>16&0xff, datapix[i][6] >>16&0xff, datapix[i][7] >>16&0xff
						);
				}
				else
				{
					sprintf( cts, "%f %f %f %f %08x\n", dataf[i][0], dataf[i][1], dataf[i][2], dataf[i][3], k );
				}
				CNFGColor( 0xffffffff );
				CNFGDrawText( cts, 2 );
				CNFGColor( k );
				CNFGTackRectangle( CNFGPenX+300, CNFGPenY, CNFGPenX+310, CNFGPenY+10 );
			}
			
			for( y = 0; y < 16; y++ )
			{
				for( x = 0; x < 8; x++ )
				{
					CNFGPenX = width+1 + x * 10; CNFGPenY = 300 + y * 10;
					uint32_t k = datapix[y+24][x];
					CNFGColor( (k<<8) | 0xff );
					CNFGTackRectangle( CNFGPenX, CNFGPenY, CNFGPenX+10, CNFGPenY+10 );
				}
			}

			uint32_t fk = htonl(datapix[24][0]<<8);
			minioscSend( osc, "/opc/zone6", ",r", fk );
			minioscSend( osc, "/opc/zoneall", ",r", fk );
#endif

		final:
						
			// Update for output.
			for( i = 0; i < width*height; i++ )
			{
				uint32_t k = bmpBuffer[i];
				bmpBuffer[i] = ((k&0x0000ff)<<8) | ((k&0x00ff00)<<8) | ((k&0xff0000)<<8) | 0xff;
			}

			// Display what we say.
			CNFGUpdateScreenWithBitmap( bmpBuffer, width, height );
		}
		else
		{
			// Keep searching
			is_real_vrchat_window = 0;
printf( "_______________\n" );
			EnumWindows( (WNDENUMPROC)EnumWindowsProc, (LPARAM)0 );
printf( "+WND: %d\n", wnd );
			CNFGPenX = 65; CNFGPenY = 0;
			CNFGDrawText( "Searching for VRChat", 2 );

			if( wnd )
			{
				printf( "Found window %d\n", wnd );
				
				screen = GetDC(wnd);
				target = CreateCompatibleDC(screen);
				printf( "WND: %d\nDC: %08x\nTARGET: %08x\n", wnd, screen, target );
				width = CAPWIDTH;
				height = DATAHEIGHT + 280;
				bmp = CreateCompatibleBitmap(screen, width, height);
			}
		}
		
		// Returns 0 if failed to find, otherwise, returns a handle.
		if( !swadge )
		{
			CNFGColor( 0xff0000ff );
			CNFGPenX = width+1; CNFGPenY = height-10;
			CNFGDrawText( "Could not connect to swadge.", 2 );
		}
		else
		{
			CNFGPenX = width+1; CNFGPenY = height-10;
			CNFGColor( 0xffffffff );
			char st[1024];
			sprintf( st, "Swadge Connected.\nSend Time: %.3fms", fSendTimeMS );
			CNFGDrawText( st, 2 );
		}

		CNFGSwapBuffers();
		Sleep(1);
	}

	return 0;
}




BOOL CALLBACK EnumWindowsProc( HWND hwnd, LONG lParam )
{
    CHAR windowname[1024] = { 0 };
    CHAR windowexe[1024] = { 0 };
	DWORD process = 0;
	DWORD r = GetWindowThreadProcessId( hwnd, &process );
	HANDLE Handle = OpenProcess(
                  PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
                  FALSE,
                  process
                );
	if (Handle)
	{
		GetModuleFileNameExA(Handle, 0, windowexe, sizeof(windowexe));
		CloseHandle(Handle);
	}
	RECT rect;
	GetWindowRect( hwnd, &rect );

	if( rect.right - rect.left == 0 && rect.bottom - rect.top == 0 )
	{
		return TRUE;
	}

	printf( "%s\n", windowexe );
    SendMessage( hwnd, WM_GETTEXT, sizeof(windowname), (LPARAM)(void*)windowname );
	

//	if( rect.right > 200 && rect.bottom > 200 )
//		printf( ":%s:%s: %d %d\n", windowname, windowname, rect.right, rect.bottom );

	if( mycasestr( windowexe, "VRChat" ) && rect.right > 10 && rect.bottom > 10 && 
		strcmp( windowname, "VRChat" ) == 0 )
	{
		printf( "%s / %s / %d %d\n", windowname, windowexe, rect.right, rect.bottom );
		printf( "********\n" );
		is_real_vrchat_window = 1;
		wnd = hwnd;
	}

//C:\Program Files\Unity\Hub\Editor\2022.3.6f1\Editor\Unity.exe / swadge-bridge-demo - VRCDefaultWorldScene - Windows, Mac, Linux - Unity 2022.3.6f1 <DX11> / 3227 / 1448 / 0 / 6279324 / 0
//printf( "%s / %s / %d / %d / %d / %d / %d\n", windowexe, windowname, rect.right, rect.bottom, is_real_vrchat_window,
//		mycasestr( windowexe, "editor\\unity" ), mycasestr( windowname, "Windows, Mac, Linux"  ) );

	if( mycasestr( windowexe, "editor\\unity" ) && rect.right > 10 && rect.bottom > 10 && 
		mycasestr( windowname, "Windows, Mac, Linux" ) && !is_real_vrchat_window )
	{
		printf( "%s / %s / %d %d\n", windowname, windowexe, rect.right, rect.bottom );
		printf( "********\n" );
		wnd = hwnd;
	}
    return TRUE;
}



const char * mycasestr( const char * haystack, const char * needle )
{
	int ch = 0;
	if( !haystack || !needle ) return 0;
	int hl = strlen( haystack );
	int nl = strlen( needle );
	for( ch = 0; ch < hl-nl; ch++ )
	{
		int m;
		for( m = 0; m < nl; m++ )
		{
			if( toupper( haystack[ch+m] ) != toupper( needle[m] ) )
			{
				break;
			}
		}
		if( m == nl )
		{
			return haystack + m;
		}
	}
	return 0;
}
