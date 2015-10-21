#pragma once

// Copyright 2015 Stellar Development Foundation and contributors. Licensed
// under the Apache License, Version 2.0. See the COPYING file at the root
// of this distribution or at http://www.apache.org/licenses/LICENSE-2.0

#include "util/Timer.h"
#include "database/Database.h"
#include <string>
#include "util/optional.h"
#include "main/Config.h"

namespace stellar
{
using namespace std;

class PeerRecord
{
  public:
    std::string mIP;
    unsigned short mPort;
    VirtualClock::time_point mNextAttempt;
    uint32_t mNumFailures;

    PeerRecord(){};

    PeerRecord(string const& ip, unsigned short port,
               VirtualClock::time_point nextAttempt, uint32_t fails = 0)
        : mIP(ip), mPort(port), mNextAttempt(nextAttempt), mNumFailures(fails)
    {
    }

    bool operator==(PeerRecord& other)
    {
        return mIP == other.mIP && mPort == other.mPort &&
               mNextAttempt == other.mNextAttempt &&
               mNumFailures == other.mNumFailures;
    }

    static bool parseIPPort(std::string const& ipPort, Application& app,
                            PeerRecord& ret,
                            unsigned short defaultPort = DEFAULT_PEER_PORT);

    static optional<PeerRecord> loadPeerRecord(Database& db, std::string ip,
                                               unsigned short port);
    static void loadPeerRecords(Database& db, uint32_t max,
                                VirtualClock::time_point nextAttemptCutoff,
                                vector<PeerRecord>& retList);

    bool isSelfAddressAndPort(std::string const& ip, unsigned short port) const;
    bool isPrivateAddress() const;
    bool isLocalhost() const;

    // returns true if peerRecord is already in the database
    bool isStored(Database& db);

    // insert record in database if it's a new record
    // returns true if inserted
    bool insertIfNew(Database& db);

    // insert or update record from database
    void storePeerRecord(Database& db);

    void resetBackOff(VirtualClock& clock);
    void backOff(VirtualClock& clock);

    void toXdr(PeerAddress& ret) const;

    static void dropAll(Database& db);
    std::string toString();

  private:
    std::chrono::seconds computeBackoff(VirtualClock& clock);
    static void ipToXdr(std::string ip, xdr::opaque_array<4U>& ret);
    static const char* kSQLCreateStatement;
};
}
