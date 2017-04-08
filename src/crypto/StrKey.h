#pragma once
// Copyright 2014 Stellar Development Foundation and contributors. Licensed
// under the Apache License, Version 2.0. See the COPYING file at the root
// of this distribution or at http://www.apache.org/licenses/LICENSE-2.0

#include "ByteSlice.h"
#include <string>

namespace stellar
{

namespace strKey
{

typedef enum {
    // version bytes - 5 bits only
    // version bytes - 5 bits only for leading letter, 3 bits for following group
    STRKEY_PUBKEY_ED25519 = (13<<3) + 0, // 'N' + [ABCD]
    STRKEY_SEED_ED25519 = (23<<3) + 6,  // 'X' + [YZ23]
    STRKEY_PRE_AUTH_TX = (19<<3),   // 'T',
    STRKEY_HASH_X = (7<<3)         // 'N'
} StrKeyVersionByte;

// Encode a version byte and ByteSlice into StrKey
std::string toStrKey(uint8_t ver, ByteSlice const& bin);

// computes the size of the StrKey that would result from encoding
// a ByteSlice of dataSize bytes
size_t getStrKeySize(size_t dataSize);

// returns true if the strKey could be decoded
bool fromStrKey(std::string const& strKey, uint8_t& outVersion,
                std::vector<uint8_t>& decoded);
}
}
