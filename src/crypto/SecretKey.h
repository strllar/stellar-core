#pragma once

// Copyright 2014 Stellar Development Foundation and contributors. Licensed
// under the Apache License, Version 2.0. See the COPYING file at the root
// of this distribution or at http://www.apache.org/licenses/LICENSE-2.0

#include "xdr/Stellar-types.h"
#include <ostream>
#include <functional>
#include <array>

namespace stellar
{

using xdr::operator==;

class ByteSlice;

class SecretKey
{
    using uint512 = xdr::opaque_array<64>;
    CryptoKeyType mKeyType;
    uint512 mSecretKey;

  public:
    SecretKey();

    struct Seed
    {
        CryptoKeyType mKeyType;
        uint256 mSeed;
    };

    // Get the public key portion of this secret key.
    PublicKey getPublicKey() const;

    // Get the seed portion of this secret key.
    Seed getSeed() const;

    // Get the seed portion of this secret key as a StrKey string.
    std::string getStrKeySeed() const;

    // Get the public key portion of this secret key as a StrKey string.
    std::string getStrKeyPublic() const;

    // Return true iff this key is all-zero.
    bool isZero() const;

    // Produce a signature of `bin` using this secret key.
    Signature sign(ByteSlice const& bin) const;

    // Create a new, random secret key.
    static SecretKey random();

    // Decode a secret key from a provided StrKey seed value.
    static SecretKey fromStrKeySeed(std::string const& strKeySeed);

    // Decode a secret key from a binary seed value.
    static SecretKey fromSeed(ByteSlice const& seed);

    bool operator==(SecretKey const& rh)
    {
        return (mKeyType == rh.mKeyType) && (mSecretKey == rh.mSecretKey);
    }
};

// public key utility functions
namespace PubKeyUtils
{
// Return true iff `signature` is valid for `bin` under `key`.
bool verifySig(PublicKey const& key, Signature const& signature,
               ByteSlice const& bin);

void clearVerifySigCache();
void flushVerifySigCacheCounts(uint64_t& hits, uint64_t& misses,
                               uint64_t& ignores);

std::string toShortString(PublicKey const& pk);

std::string toStrKey(PublicKey const& pk);

PublicKey fromStrKey(std::string const& s);

// returns hint from key
SignatureHint getHint(PublicKey const& pk);
// returns true if the hint matches the key
bool hasHint(PublicKey const& pk, SignatureHint const& hint);

PublicKey random();
}

namespace StrKeyUtils
{
// logs a key (can be a public or private key) in all
// known formats
void logKey(std::ostream& s, std::string const& key);
}

namespace HashUtils
{
Hash random();
}
}

namespace std
{
template <> struct hash<stellar::PublicKey>
{
    size_t operator()(stellar::PublicKey const& x) const noexcept;
};
}
