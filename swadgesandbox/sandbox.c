#include <stdio.h>
#include <string.h>
#include "esp_system.h"
#include "hal/gpio_types.h"
#include "esp_log.h"
#include "soc/efuse_reg.h"
#include "rtc_wdt.h"
#include "soc/soc.h"
#include "soc/system_reg.h"
#include "esp_wifi.h"
#include "esp_private/wifi.h"
#include "hdw-btn.h"
#include "mainMenu.h"
#include "hdw-esp-now.h"

#include "nvs_flash.h"
#include "nvs.h"

#define FSNET_CODE_SERVER 0x73534653
#define FSNET_CODE_PEER 0x66534653

int espNowIsInit = 0;
int global_i = 100;
menu_t * menu;
menuLogbookRenderer_t* menuLogbookRenderer;
font_t logbook;





extern fnAdvancedUsbHandler advancedUsbHandler;
int16_t sandboxAdvancedUSB(uint8_t* buffer, uint16_t length, uint8_t isGet);

static char* local_hid_string_descriptor[5] = {
    // array of pointer to string descriptors
    (char[]){0x09, 0x04},   // 0: is supported language is English (0x0409)
    "Magfest",              // 1: Manufacturer
    "Swadge Controller",    // 2: Product
    "WIFIBRIDGE",               // 3: Serials, should use chip ID
    "Swadge HID interface", // 4: HID
};


// clang-format off
#define TUD_HID_REPORT_DESC_NIL(...) \
  HID_USAGE_PAGE ( HID_USAGE_PAGE_DESKTOP     )                 ,\
  HID_USAGE      ( HID_USAGE_DESKTOP_GAMEPAD  )                 ,\
  HID_COLLECTION ( HID_COLLECTION_APPLICATION )                 ,\
    /* Allow for 0xaa (regular size), 0xab (jumbo sized) and 0xac mini feature reports; Windows needs specific id'd and size'd endpoints. */ \
    HID_REPORT_COUNT ( CFG_TUD_ENDPOINT0_SIZE                 ) ,\
    HID_REPORT_SIZE  ( 8                                      ) ,\
    HID_REPORT_ID    ( 0xaa                                   ) \
    HID_USAGE        ( HID_USAGE_DESKTOP_GAMEPAD              ) ,\
    HID_FEATURE      ( HID_DATA | HID_ARRAY | HID_ABSOLUTE    ) ,\
    HID_REPORT_COUNT ( (255-1)         ) ,\
    HID_REPORT_ID    ( 0xab                                   ) \
    HID_USAGE        ( HID_USAGE_DESKTOP_GAMEPAD              ) ,\
    HID_FEATURE      ( HID_DATA | HID_ARRAY | HID_ABSOLUTE    ) ,\
    HID_REPORT_COUNT ( 1                                      ) ,\
    HID_REPORT_ID    ( 0xac                                   ) \
    HID_USAGE        ( HID_USAGE_DESKTOP_GAMEPAD              ) ,\
    HID_FEATURE      ( HID_DATA | HID_ARRAY | HID_ABSOLUTE    ) ,\
    HID_REPORT_COUNT ( (255-1)         ) ,\
    HID_REPORT_ID    ( 0xad                                   ) \
    HID_USAGE        ( HID_USAGE_DESKTOP_GAMEPAD              ) ,\
    HID_FEATURE      ( HID_DATA | HID_ARRAY | HID_ABSOLUTE    ) ,\
  HID_COLLECTION_END
// clang-format on

static const uint8_t local_hid_report_descriptor[] = {TUD_HID_REPORT_DESC_NIL()};

static const uint8_t local_hid_configuration_descriptor[] = {
    TUD_CONFIG_DESCRIPTOR(1,                                                        // Configuration number
                          1,                                                        // interface count
                          0,                                                        // string index
                          (TUD_CONFIG_DESC_LEN + (CFG_TUD_HID * TUD_HID_DESC_LEN)), // total length
                          TUSB_DESC_CONFIG_ATT_REMOTE_WAKEUP,                       // attribute
                          100),                                                     // power in mA

    TUD_HID_DESCRIPTOR(0,                             // Interface number
                       4,                             // string index
                       false,                         // boot protocol
                       sizeof(local_hid_report_descriptor), // report descriptor len
                       0x81,                          // EP In address
                       64,                            // size
                       1),                           // polling interval
};





#define RFRXQUEUESIZE 16
struct RFRXQueueElement
{
	uint8_t data[256]; //igi, mac, data.
	int datasize;
};
struct RFRXQueueElement rqueue[RFRXQUEUESIZE];
int rqueuehead, rqueuetail;


const char * menu_MainMenu = "Main Menu";
const char * menu_Bootload = "Bootloader";

// External functions defined in .S file for you assembly people.
void minimal_function();
uint32_t asm_read_gpio();

static void mainMenuCb(const char* label, bool selected, uint32_t settingVal)
{
	if( !selected ) return;

    if( label == mainMenuMode.modeName )
    {
        switchToSwadgeMode( &mainMenuMode );
    }
    else if( label == menu_Bootload )
    {
        // Uncomment this to reboot the chip into the bootloader.
        // This is to test to make sure we can call ROM functions.
        REG_WRITE(RTC_CNTL_OPTION1_REG, RTC_CNTL_FORCE_DOWNLOAD_BOOT);
        void software_reset( uint32_t x );
        software_reset( 0 );
    }
}

void sandboxRxESPNow(const esp_now_recv_info_t* esp_now_info, const uint8_t* data, uint8_t len,
                                   int8_t rssi)
{
	int next = (rqueuehead+1) & (RFRXQUEUESIZE-1);
	if( next == rqueuetail ) return;
	if( len > 256 - 7 ) return;
	
	//Otherwise, we're good!
	struct RFRXQueueElement * q = rqueue + rqueuehead;
	q->datasize = len+7;
	q->data[0] = rssi;
	memcpy( q->data+1, esp_now_info->src_addr, 6 );
	memcpy( q->data+7, data, len );
	rqueuehead = next;
}

uint32_t stime;
void sandboxTxESPNow(const uint8_t* mac_addr, esp_now_send_status_t status)
{
	//uint32_t end = esp_timer_get_time();
	//uprintf( "ESP-NOW>%d %d\n", status, end-stime );
}

int dummy( uint32_t a, uint32_t b )
{
	ESP_LOGI( ".", "DUMMY %08lx %08lx\n", a, b );
	return 0;
}



void sandbox_main( void )
{
	espNowIsInit = 0;

	ESP_LOGI( ".", "Running from IRAM. %d\n", global_i );
	esp_log_level_set( "*", ESP_LOG_VERBOSE ); // Enable logging if there's any way.

	ESP_LOGI( "sandbox", "Running from IRAM. %d", global_i );

	extern const tusb_desc_device_t descriptor_dev_kconfig;
	void tinyusb_set_descriptor( const tusb_desc_device_t * dev_descriptor, const char **str_desc, int str_desc_count, const uint8_t *cfg_desc);
	initTusb( (const tinyusb_config_t *)&descriptor_dev_kconfig, local_hid_report_descriptor );
    tinyusb_set_descriptor(&descriptor_dev_kconfig, local_hid_string_descriptor, 5, local_hid_configuration_descriptor);
	tud_disconnect();
    tusb_init();
	int i;	for( i = 0; i < 10000; i++ ) asm volatile( "nop" ); tud_connect();

	advancedUsbHandler = sandboxAdvancedUSB;

    ESP_LOGI( "sandbox", "Running from IRAM. %d", global_i );

    //REG_WRITE( GPIO_FUNC7_OUT_SEL_CFG_REG,4 ); // select ledc_ls_sig_out0

    menu = initMenu("USB Sandbox", mainMenuCb);
    addSingleItemToMenu(menu, mainMenuMode.modeName);
    addSingleItemToMenu(menu, menu_Bootload);
    loadFont("logbook.font", &logbook, false);
    menuLogbookRenderer = initMenuLogbookRenderer(&logbook);

	ESP_LOGI( ".", "Installing espnow.\n" );

//    espNowInit(&sandboxRxESPNow, &sandboxTxESPNow, GPIO_NUM_NC,
//		GPIO_NUM_NC, UART_NUM_MAX, ESP_NOW_IMMEDIATE);

	esp_err_t er = initEspNow(&sandboxRxESPNow, &sandboxTxESPNow, GPIO_NUM_NC,
		GPIO_NUM_NC, UART_NUM_MAX, ESP_NOW_IMMEDIATE);


	ESP_LOGI( ".", "Loaded (%d)\n", er );
	espNowIsInit = 1;
}

void sandbox_exit()
{
	espNowIsInit = 0; 
	ESP_LOGI( ".",  "Exit\n" );
    if( menu )
    {
        deinitMenu(menu);
    }
	ESP_LOGI( ".",  "Exit Complete\n" );
}


void sandbox_tick()
{
	if( menu )
	    drawMenuLogbook(menu, menuLogbookRenderer, 1);

    buttonEvt_t evt              = {0};
    while (checkButtonQueueWrapper(&evt))
    {
        menu = menuButton(menu, evt);
    }
#if 0
	static int seed = 0;
	int iter;
	for( iter = 0; iter < 10; iter++ )
	{
		seed++;
	//	uint32_t end = getCycleCount();
	//	uprintf( "SPROF: %d\n", end-start );

	//INTERESTING
	//	int32_t rom_read_hw_noisefloor();
	//	uprintf( "%d\n", rom_read_hw_noisefloor() );

		uint32_t now = esp_timer_get_time();
		uint8_t buff[256];
		uint8_t * pack = buff;

		*((uint32_t*)pack) = FSNET_CODE_SERVER;  pack += 4;

		*((uint32_t*)pack) = now;  pack += 4; // protVer, models, ships, boolets in UEQ.
		uint32_t assetCounts = 0;
		int acbits = 0;
		int sendmod = 2;
		int sendshp = 2;
		int sendboo = 2;
		acbits += WriteUEQ( &assetCounts, 1 );
		acbits += WriteUEQ( &assetCounts, sendmod ); //models
		acbits += WriteUEQ( &assetCounts, sendshp ); // ships
		acbits += WriteUEQ( &assetCounts, sendboo ); // boolets
		FinalizeUEQ( &assetCounts, acbits );
		*((uint32_t*)pack) = assetCounts; pack += 4;

		static int send_no;
		send_no+=2;
		if( send_no >= 80 ) send_no = 0;

		for( i = 0; i < sendmod; i++ )
		{
			int nrbones = 16;
			// First is a codeword.  Contains ID, bones, bone mapping.
			uint32_t codeword = (send_no+i) | ((nrbones-1)<<8);

			int sbl = 4+8;
			for( j = 0; j < nrbones; j++ )
			{
				int v = !(j==5|| j == 11);
				codeword |= v << (sbl++);

				if( !v )
				{
					//Do we reset back to zero?
					codeword |= 0 << (sbl++);  // 0 is yes, reset back to zero.
					codeword |= 1 << (sbl++);  // Do we draw another line from zero?
				}
			}
			*((uint32_t*)pack) = codeword; pack += 4;

			int16_t loc[3];
			int ang = ((now >> 19)+i*30) % 360;
			loc[0] = speedyHash(seed)>>6;//getSin1024( ang )>>2;
			loc[1] = i+send_no+1000+(speedyHash(seed)>>6);
			loc[2] = speedyHash(seed)>>6;//getCos1024( ang )>>2;
			memcpy( pack, loc, sizeof( loc ) ); pack += sizeof( loc );
			*(pack++) = 255; // radius
			*(pack++) = (i+send_no+iter*10)%216; // req color
			int8_t vel[3] = { 0 };
			memcpy( pack, vel, sizeof( vel ) ); pack += sizeof( vel );

			for( j = 0; j < nrbones; j++ )
			{
				int8_t bone[3];
				int ang = ((now >> 13)+j*40) % 360;
				bone[0] = getSin1024( ang )>>5;
				bone[1] = getCos1024( ang )>>5;
				bone[2] = 30;
				memcpy( pack, bone, sizeof( bone ) ); pack += sizeof( bone );
			}
		}

		for( i = 0; i < sendshp; i++ )
		{
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
		// Now, need to send boolets.
		for( i = 0; i < sendboo; i++ )
		{
			int16_t loc[3];
			int16_t rot[2] = { 0 };
			rot[1] = 1000;
			uint16_t bid = i+1 +send_no;

			int ang = (i*30+(now >> 12)) % 360;
			loc[0] = getSin1024( ang )>>3;
			loc[1] = 500;
			loc[2] = getCos1024( ang )>>3;

		    *(pack++) = i+send_no; // Local "bulletID"
		    memcpy( pack, &now, sizeof(now) ); pack += sizeof( now );
		    memcpy( pack, loc, sizeof(loc) ); pack += sizeof( loc );
		    memcpy( pack, rot, sizeof(rot) ); pack += sizeof( rot );
		    memcpy( pack, &bid, sizeof(bid) ); pack += sizeof( bid );
		}

		int len = pack - buff;
		uprintf( "len: %d\n", len );
		now = esp_timer_get_time();
		espNowSend((char*)buff, len); //Don't enable yet.
		stime = now;
	}
	#endif
}

void sandboxBackgroundDrawCallback(int16_t x, int16_t y, int16_t w, int16_t h, int16_t up, int16_t upNum )
{
}

int16_t sandboxAdvancedUSB(uint8_t * buffer, uint16_t length, uint8_t isGet )
{
	if( isGet )
	{
		if( rqueuehead == rqueuetail ) return 1;

		struct RFRXQueueElement * q = rqueue + rqueuetail;
		int len = q->datasize;
		ESP_LOGI( "+", "DS// %02x %02x %d\n", buffer[0], buffer[1], length );
		memcpy( buffer, q->data, len );
		
		rqueuetail = (rqueuetail+1)&(RFRXQUEUESIZE-1);
		return len;
	}
	else
	{
		if( espNowIsInit )
		{
			ESP_LOGI( "+", "SEND// %02x %02x %d\n", buffer[0], buffer[1], length );
			espNowSend((char*)(buffer+2), buffer[1]);
		}
		return length;
	}
}

swadgeMode_t sandbox_mode =
{
    .modeName = "usb_wifi_base",
    .fnEnterMode = sandbox_main,
    .fnExitMode = sandbox_exit,
    .fnMainLoop = sandbox_tick,
    .fnBackgroundDrawCallback = sandboxBackgroundDrawCallback,
	.overrideUsb = true,
	.fnAdvancedUSB = sandboxAdvancedUSB,
    .wifiMode = NO_WIFI,
    .fnAudioCallback = NULL,
};

