#define MAX_PEERS MAX_RTMP_PLAYERS
#define BOOLETSPERPLAYER 4
#define MAX_BOOLETS (MAX_PEERS*BOOLETSPERPLAYER)

void * RTMPTransmitThread( void * v )
{
	printf( "RTMPTransmitThread()\n" );
	#define INTERNAL_RTMP_RAW_DATA_PORT 39937

	static uint8_t rawFrameBuffer[128*96];

	struct sockaddr_in     servaddr;
	int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
	if( sockfd <= 0 )
	{
		fprintf( stderr, "Error: cannot createRTMP sender socket\n" );
		exit( -9 );
	}

	memset(&servaddr, 0, sizeof(servaddr));
	servaddr.sin_family = AF_INET;
	servaddr.sin_port = htons(INTERNAL_RTMP_RAW_DATA_PORT);
	servaddr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

	uint32_t frameno;
	while(1)
	{
		uint32_t usNow = OGGetAbsoluteTime()*1000000;
		frameno++;
		
		if( demomode )
		{
			OGLockMutex( rtmpOutLock );
			boolet_t * b = gOboolets;
			boolet_t * bend = b + (MAX_RTMP_PLAYERS*4);
			int bid = 0;
			for( ; b != bend; b++, bid++ )
			{
				int pid = bid / 4;
				b->timeOfLaunch = (usNow + 1000000*((bid&3)));
				b->launchLocation[0] = sin( pid * 0.5+ frameno*.01 ) * 1280;
				b->launchLocation[1] = pid*8+(bid&3);
				b->launchLocation[2] = cos( pid * 0.5 + frameno*.01 ) * 1280;
				b->launchRotation[0] = (pid*2)*15;
				b->launchRotation[1] = (pid*.5+frameno*.5)*15;
				b->flags = bid;
			}

			
			multiplayerpeer_t * p = gOplayers;
			multiplayerpeer_t * pend = p + MAX_RTMP_PLAYERS;
			int pid = 0;
			for( ; p != pend; p++, pid++ )
			{
				p->timeOffsetOfPeerFromNow = 0; // UNTRANSMITTED
				memset( p->mac, 0, sizeof( p->mac ) ); // UNTRANSMITTED
				p->framesDead = 0;               //UNTRANSMITTED

				p->timeOfUpdate = usNow-500;
				p->posAt[0] = sin( pid * 0.5 + frameno*.01 ) * 1280;
				p->posAt[1] = pid*8;
				p->posAt[2] = cos( pid * 0.5 + frameno*.01 ) * 1280;
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
			OGUnlockMutex( rtmpOutLock );
		}


		int akey = 0;
		#define g_mbw 8
		#define g_mbh 6
		int w = g_mbw * 16;
		int h = g_mbh * 16;
		int bk;
		multiplayerpeer_t * p;
		boolet_t * b;

		for( bk = 0; bk < g_mbw*g_mbh; bk++ )
		{

			OGLockMutex( rtmpOutLock );
			int mbx = 0;
			int mby = 0;

			int basecolor = akey?254:1;
			uint8_t * buffer = malloc( 256 );
			memset( buffer, 0xff, 256 );
			{
				mbx = bk%g_mbw;
				mby = (bk/g_mbw)%g_mbh;
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
					
					int num = usNow / 1000;
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
							p = &gOplayers[shipid];
							b = &gOboolets[shipid*4];

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
			OGUnlockMutex( rtmpOutLock );

			int x, y;
			for( y = 0; y < 16; y++ )
			{
				uint8_t * src = buffer + y*16;
				uint8_t * dest = rawFrameBuffer + ((mbx*16+((y+mby*16))*w));
				memcpy( dest, src, 16 );
			}
		}
		//memset( rawFrameBuffer, 0xff, 128*10 );
		int r = sendto(sockfd, rawFrameBuffer, sizeof(rawFrameBuffer),
			0, (const struct sockaddr *) &servaddr, sizeof(servaddr));
		if( r != sizeof(rawFrameBuffer) )
		{
			fprintf( stderr, "Error sending to RTMP local relay (%d != %d)\n", r, sizeof( rawFrameBuffer ) );
		}
		
		Sleep( 40 );
	}
}

void * SwadgeReceiver( void * v )
{
	double LastTimeHeardFromPeer[MAX_RTMP_PLAYERS];
	
	while( 1 )
	{
		uint8_t data[257];
		int keepgoings;
		
		// Eventually we need to break out of this and address any possible timeouts, etc.
		for( keepgoings = 0; keepgoings < 100; keepgoings++ )
		{
			data[0] = 173;
			int r;
			if( swadge )
				r = hid_get_feature_report( swadge, data, 257 );
			else
				r = -9;

			if( r < 0 ) {
				//printf( "00Setu %d %d\n", r, HidMutex );
				OGLockMutex(HidMutex);
				//printf( "10Setu %d\n", r );
				if( swadge ) hid_close( swadge );
				//printf( "Setu\n" );
				swadge = swadgehost_setup();
				//printf( "SC: %d\n", swadge );
				OGUnlockMutex( HidMutex );
			}

			if( r < 7 ) break; // break = go to sleep for a bit.
			
			if( memcmp( data+7, "\x53\x46\x53\x66", 4 ) != 0 )
			{
				continue;
			}
			
			int i;
			
			if( 0 ) // debug.
			{
				printf( "%d :", r );
				int i;
				for( i = 0; i < r; i++ )
				{
					printf( "%02x ", data[i] );
				}
				printf( "\n" );
			}
			
			for( i = 0; i < MAX_RTMP_PLAYERS; i++ )
			{
				if( memcmp( gOplayers[i].mac, data+1, 6 ) == 0 )
				{
					break;
				}
			}
			if( i == MAX_RTMP_PLAYERS )
			{
				for( i = 0; i < MAX_RTMP_PLAYERS; i++ )
				{
					if( memcmp( gOplayers[i].mac, "\x00\x00\x00\x00\x00\x00", 6 ) == 0 )
					{
						memcpy( gOplayers[i].mac, data+1, 6 );
						break;
					}
				}
			}
			if( i == MAX_RTMP_PLAYERS )
			{
				// No room in player list :(
				printf( "Player found but not enough room in list for them :( sorry.\n" );
				break;
			}
			double dNow = OGGetAbsoluteTime();
			uint32_t usNow = dNow * 1000000;
			int peerId = i;
			
			multiplayerpeer_t * thisPeer = gOplayers + peerId;

			uint8_t * pptr = data+11;
			uint32_t timeOnPeer;
			memcpy( &timeOnPeer, pptr, 4 ); pptr += 4;

			// Refine time offset.  TODO: Use asymmetric filter.
			int32_t estTimeOffsetError = timeOnPeer - (thisPeer->timeOffsetOfPeerFromNow + usNow);
			thisPeer->timeOffsetOfPeerFromNow += estTimeOffsetError>>3;

			// Compute "now" in peer time.
			uint32_t peerSendInOurTime = timeOnPeer - thisPeer->timeOffsetOfPeerFromNow;

			// We are only accepting peers.
			int isPeer = 1; int readID = 0;
			
			multiplayerpeer_t * allPeers = gOplayers;
			LastTimeHeardFromPeer[peerId] = dNow;
			
			if( demomode )
			{
				// Zero out the demomode.
				memset( gOplayers, 0, sizeof( gOplayers ) );
				memset( gOboolets, 0, sizeof( gOboolets ) );
				demomode = 0;
			}
			
			OGLockMutex( rtmpOutLock );
			
			uint32_t assetCounts;
			memcpy( &assetCounts, pptr, 4 ); pptr += 4;
			
		    int protVer = ReadUEQ( &assetCounts );
			if( protVer != 1 ) continue; // Try not to rev version.
			int networkModelCount = ReadUEQ( &assetCounts );
			
			for( i = 0; i < networkModelCount; i++ )
			{
				uint32_t codeword = (*(const uint32_t*)pptr);  pptr += 4;
				uint32_t res_codeword = codeword;
				uint32_t id = ReadUQ( &codeword, 8 );
				uint32_t bones = ReadUQ( &codeword, 4 ) + 1;

				network_model_t * m = 0;
				pptr += sizeof(m->root); 
				(*pptr++);  //m->radius
				(*pptr++);  //m->reqColor
				pptr+= sizeof(m->velocity); 
				pptr += bones * 3;
			}

			int shipCount = ReadUEQ( &assetCounts );

			for( i = 0; i < shipCount; i++ )
			{
				int readID = *(pptr++);
				int shipNo = isPeer?peerId:readID;

				if( shipNo >= MAX_PEERS ) shipNo = 0;

				multiplayerpeer_t * tp = allPeers + shipNo;
				tp->timeOfUpdate = peerSendInOurTime;

				// Pos, Vel, Rot, RotVel + flags.
				memcpy( tp->posAt, pptr, sizeof( tp->posAt ) ); pptr+=sizeof( tp->posAt );
				memcpy( tp->velAt, pptr, sizeof( tp->velAt ) ); pptr+=sizeof( tp->velAt );
				memcpy( tp->rotAt, pptr, sizeof( tp->rotAt ) ); pptr+=sizeof( tp->rotAt );
				memcpy( &tp->basePeerFlags, pptr, sizeof( tp->basePeerFlags ) ); pptr+=sizeof( tp->basePeerFlags ); tp->basePeerFlags |= 1;
				memcpy( &tp->auxPeerFlags, pptr, sizeof( tp->auxPeerFlags ) ); pptr+=sizeof( tp->auxPeerFlags );
				tp->reqColor = *(pptr++);
				
				// XXX HACK UNIVERSE FLIP.
				tp->posAt[0] = -tp->posAt[0];
				tp->velAt[0] = -tp->velAt[0];
				tp->rotAt[0] = -tp->rotAt[0];

				//uprintf( "%d %d %d - %d %d %d - %d %d %d %08x %08x\n", tp->posAt[0],tp->posAt[1],tp->posAt[2],tp->velAt[0], tp->velAt[1], tp->velAt[2], 
				//    tp->rotAt[0], tp->rotAt[1], tp->rotAt[2], tp->basePeerFlags, tp->auxPeerFlags );

				// I don't think we care about this for the host.
				/*
				if( tp->basePeerFlags & 2 )
				{
					if( tp->framesDead == 0 )
					{
						tp->framesDead = 1;
					}
				}
				else
				{
					tp->framesDead = 0;
				}*/
			}

			int booletCount = ReadUEQ( &assetCounts );
			boolet_t * allBoolets = gOboolets;
			for( i = 0; i < booletCount; i++ )
			{
				int booletID = *(pptr++);
				if( isPeer )
				{
					if( booletID >= BOOLETSPERPLAYER ) booletID = BOOLETSPERPLAYER;

					// Fixed locations.
					booletID += peerId*BOOLETSPERPLAYER;
				}
				else
				{
					if( booletID >= MAX_BOOLETS ) booletID = 0;
				}
				boolet_t * b = allBoolets + booletID;
				b->timeOfLaunch = *((const uint32_t*)pptr) - thisPeer->timeOffsetOfPeerFromNow;
				pptr += 4;
				memcpy( b->launchLocation, pptr, sizeof(b->launchLocation) );
				pptr += sizeof(b->launchLocation);
				memcpy( b->launchRotation, pptr, sizeof(b->launchRotation) );
				pptr += sizeof(b->launchRotation);
				memcpy( &b->flags, pptr, sizeof(b->flags) ); pptr+=sizeof(b->flags);
				
				// XXX UNIVERSE FLIP
				b->launchLocation[0] = -b->launchLocation[0];
				b->launchRotation[0] = -b->launchRotation[0];
			}

			OGUnlockMutex( rtmpOutLock );
		}

		int i;
		double dNow = OGGetAbsoluteTime();
		for( i = 0; i < MAX_RTMP_PLAYERS; i++ )
		{
			if( dNow - LastTimeHeardFromPeer[i] > 12 && memcmp( gOplayers[i].mac, "\x00\x00\x00\x00\x00\x00", 6 ) != 0 )
			{
				// Player timed out.
				OGLockMutex( rtmpOutLock );
				memset( gOplayers + i, 0, sizeof( multiplayerpeer_t ) );
				memset( gOboolets + (i*4), 0, sizeof( boolet_t ) * 4 );
				OGUnlockMutex( rtmpOutLock );
			}
		}
		Sleep(1);		
	}
}
