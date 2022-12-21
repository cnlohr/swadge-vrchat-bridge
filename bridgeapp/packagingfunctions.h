#ifndef PACKAGING_FUNCTIONS_H
#define PACKAGING_FUNCTIONS_H


#define FSNET_CODE_SERVER 0x73534653
#define FSNET_CODE_PEER 0x66534653


#define speedyHash( seed ) (( seed = (seed * 1103515245) + 12345 ), seed>>16 )


static uint32_t ReadUQ( uint32_t * rin, uint32_t bits )
{
    uint32_t ri = *rin;
    *rin = ri >> bits;
    return ri & ((1<<bits)-1);
}

static uint32_t PeekUQ( uint32_t * rin, uint32_t bits )
{
    uint32_t ri = *rin;
    return ri & ((1<<bits)-1);
}

static uint32_t ReadBitQ( uint32_t * rin )
{
    uint32_t ri = *rin;
    *rin = ri>>1;
    return ri & 1;
}

static uint32_t ReadUEQ( uint32_t * rin )
{
    if( !*rin ) return 0; //0 is invalid for reading Exp-Golomb Codes
    // Based on https://stackoverflow.com/a/11921312/2926815
    int32_t zeroes = 0;
    while( ReadBitQ( rin ) == 0 ) zeroes++;
    uint32_t ret = 1 << zeroes;
    for (int i = zeroes - 1; i >= 0; i--)
        ret |= ReadBitQ( rin ) << i;
    return ret - 1;
}

static int WriteUQ( uint32_t * v, uint32_t number, int bits )
{
    uint32_t newv = *v;
    newv <<= bits;
    *v = newv | number;
    return bits;
}

static int WriteUEQ( uint32_t * v, uint32_t number )
{
    int numvv = number+1;
    int gqbits = 0;
    while ( numvv >>= 1)
    {
        gqbits++;
    }
    *v <<= gqbits;
    return WriteUQ( v,number+1, gqbits+1 ) + gqbits;
}

static void FinalizeUEQ( uint32_t * v, int bits )
{
    uint32_t vv = *v;
    uint32_t temp = 0;
    for( ; bits != 0; bits-- )
    {
        int lb = vv & 1;
        vv>>=1;
        temp<<=1;
        temp |= lb;
    }
    *v = temp;
}


#endif