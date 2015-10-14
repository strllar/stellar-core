// Copyright 2014 Stellar Development Foundation and contributors. Licensed
// under the Apache License, Version 2.0. See the COPYING file at the root
// of this distribution or at http://www.apache.org/licenses/LICENSE-2.0

#include "Slot.h"

#include <functional>
#include "util/types.h"
#include "xdrpp/marshal.h"
#include "crypto/Hex.h"
#include "crypto/SHA.h"
#include "util/Logging.h"
#include "scp/LocalNode.h"
#include "lib/json/json.h"
#include "util/make_unique.h"
#include "util/GlobalChecks.h"

namespace stellar
{
using xdr::operator==;
using xdr::operator<;
using namespace std::placeholders;

Slot::Slot(uint64 slotIndex, SCP& scp)
    : mSlotIndex(slotIndex)
    , mSCP(scp)
    , mBallotProtocol(*this)
    , mNominationProtocol(*this)
{
}

Value const&
Slot::getLatestCompositeCandidate()
{
    return mNominationProtocol.getLatestCompositeCandidate();
}

std::vector<SCPEnvelope>
Slot::getLatestMessagesSend() const
{
    std::vector<SCPEnvelope> res;
    SCPEnvelope* e;
    e = mNominationProtocol.getLastMessageSend();
    if (e)
    {
        res.emplace_back(*e);
    }
    e = mBallotProtocol.getLastMessageSend();
    if (e)
    {
        res.emplace_back(*e);
    }
    return res;
}

void
Slot::setStateFromEnvelope(SCPEnvelope const& e)
{
    if (e.statement.nodeID == getSCP().getLocalNodeID() &&
        e.statement.slotIndex == mSlotIndex)
    {
        if (e.statement.pledges.type() ==
            SCPStatementType::SCP_ST_NOMINATE)
        {
            mNominationProtocol.setStateFromEnvelope(e);
        }
        else
        {
            mBallotProtocol.setStateFromEnvelope(e);
        }
    }
    else
    {
        CLOG(DEBUG, "SCP") << "Slot::setStateFromEnvelope invalid envelope"
            << " i: " << getSlotIndex() << " " << envToStr(e);
    }
}

std::vector<SCPEnvelope>
Slot::getCurrentState() const
{
    std::vector<SCPEnvelope> res;
    res = mNominationProtocol.getCurrentState();
    auto r2 = mBallotProtocol.getCurrentState();
    res.insert(res.end(), r2.begin(), r2.end());
    return res;
}

void
Slot::recordStatement(SCPStatement const& st)
{
    mStatementsHistory.emplace_back(st);
}

SCP::EnvelopeState
Slot::processEnvelope(SCPEnvelope const& envelope)
{
    dbgAssert(envelope.statement.slotIndex == mSlotIndex);

    CLOG(DEBUG, "SCP") << "Slot::processEnvelope"
                       << " i: " << getSlotIndex() << " " << envToStr(envelope);

    SCP::EnvelopeState res;

    try
    {

        if (envelope.statement.pledges.type() ==
            SCPStatementType::SCP_ST_NOMINATE)
        {
            res = mNominationProtocol.processEnvelope(envelope);
        }
        else
        {
            res = mBallotProtocol.processEnvelope(envelope);
        }
    }
    catch (...)
    {
        Json::Value info;

        dumpInfo(info);

        CLOG(ERROR, "SCP") << "Exception in processEnvelope "
                           << "state: " << info.toStyledString()
                           << " processing envelope: " << envToStr(envelope);

        throw;
    }
    return res;
}

bool
Slot::abandonBallot()
{
    return mBallotProtocol.abandonBallot();
}

bool
Slot::bumpState(Value const& value, bool force)
{

    return mBallotProtocol.bumpState(value, force);
}

bool
Slot::nominate(Value const& value, Value const& previousValue, bool timedout)
{
    return mNominationProtocol.nominate(value, previousValue, timedout);
}

SCPEnvelope
Slot::createEnvelope(SCPStatement const& statement)
{
    SCPEnvelope envelope;

    envelope.statement = statement;
    auto& mySt = envelope.statement;
    mySt.nodeID = getSCP().getLocalNodeID();
    mySt.slotIndex = getSlotIndex();

    mSCP.getDriver().signEnvelope(envelope);

    return envelope;
}

Hash
Slot::getCompanionQuorumSetHashFromStatement(SCPStatement const& st)
{
    Hash h;
    switch (st.pledges.type())
    {
    case SCP_ST_PREPARE:
        h = st.pledges.prepare().quorumSetHash;
        break;
    case SCP_ST_CONFIRM:
        h = st.pledges.confirm().quorumSetHash;
        break;
    case SCP_ST_EXTERNALIZE:
        h = st.pledges.externalize().commitQuorumSetHash;
        break;
    case SCP_ST_NOMINATE:
        h = st.pledges.nominate().quorumSetHash;
        break;
    default:
        dbgAbort();
    }
    return h;
}

std::vector<Value>
Slot::getStatementValues(SCPStatement const& st)
{
    std::vector<Value> res;
    if (st.pledges.type() == SCP_ST_NOMINATE)
    {
        res = NominationProtocol::getStatementValues(st);
    }
    else
    {
        res.emplace_back(BallotProtocol::getWorkingBallot(st).value);
    }
    return res;
}

SCPQuorumSetPtr
Slot::getQuorumSetFromStatement(SCPStatement const& st)
{
    SCPQuorumSetPtr res;
    SCPStatementType t = st.pledges.type();

    if (t == SCP_ST_EXTERNALIZE)
    {
        res = LocalNode::getSingletonQSet(st.nodeID);
    }
    else
    {
        Hash h;
        if (t == SCP_ST_PREPARE)
        {
            h = st.pledges.prepare().quorumSetHash;
        }
        else if (t == SCP_ST_CONFIRM)
        {
            h = st.pledges.confirm().quorumSetHash;
        }
        else if (t == SCP_ST_NOMINATE)
        {
            h = st.pledges.nominate().quorumSetHash;
        }
        else
        {
            dbgAbort();
        }
        res = getSCPDriver().getQSet(h);
    }
    return res;
}

void
Slot::dumpInfo(Json::Value& ret)
{
    Json::Value slotValue;
    slotValue["index"] = static_cast<int>(mSlotIndex);

    int count = 0;
    for (auto& item : mStatementsHistory)
    {
        slotValue["statements"][count++] = envToStr(item);
    }

    mNominationProtocol.dumpInfo(slotValue);
    mBallotProtocol.dumpInfo(slotValue);

    ret["slot"].append(slotValue);
}

std::string
Slot::getValueString(Value const& v) const
{
    return getSCPDriver().getValueString(v);
}

std::string
Slot::ballotToStr(SCPBallot const& ballot) const
{
    std::ostringstream oss;

    oss << "(" << ballot.counter << "," << getValueString(ballot.value) << ")";
    return oss.str();
}

std::string
Slot::ballotToStr(std::unique_ptr<SCPBallot> const& ballot) const
{
    std::string res;
    if (ballot)
    {
        res = ballotToStr(*ballot);
    }
    else
    {
        res = "(<null_ballot>)";
    }
    return res;
}

std::string
Slot::envToStr(SCPEnvelope const& envelope) const
{
    return envToStr(envelope.statement);
}

std::string
Slot::envToStr(SCPStatement const& st) const
{
    std::ostringstream oss;

    Hash qSetHash = getCompanionQuorumSetHashFromStatement(st);

    oss << "{ENV@" << PubKeyUtils::toShortString(st.nodeID) << " | "
        << " i: " << st.slotIndex;
    switch (st.pledges.type())
    {
    case SCPStatementType::SCP_ST_PREPARE:
    {
        auto const& p = st.pledges.prepare();
        oss << " | PREPARE"
            << " | D: " << hexAbbrev(qSetHash)
            << " | b: " << ballotToStr(p.ballot)
            << " | p: " << ballotToStr(p.prepared)
            << " | p': " << ballotToStr(p.preparedPrime) << " | nc: " << p.nC
            << " | nP: " << p.nP;
    }
    break;
    case SCPStatementType::SCP_ST_CONFIRM:
    {
        auto const& c = st.pledges.confirm();
        oss << " | CONFIRM"
            << " | D: " << hexAbbrev(qSetHash) << " | np: " << c.nPrepared
            << " | c: " << ballotToStr(c.commit) << " | nP: " << c.nP;
    }
    break;
    case SCPStatementType::SCP_ST_EXTERNALIZE:
    {
        auto const& ex = st.pledges.externalize();
        oss << " | EXTERNALIZE"
            << " | c: " << ballotToStr(ex.commit) << " | nP: " << ex.nP
            << " | (lastD): " << hexAbbrev(qSetHash);
    }
    break;
    case SCPStatementType::SCP_ST_NOMINATE:
    {
        auto const& nom = st.pledges.nominate();
        oss << " | NOMINATE"
            << " | D: " << hexAbbrev(qSetHash) << " | X: {";
        for (auto const& v : nom.votes)
        {
            oss << " '" << getValueString(v) << "',";
        }
        oss << "}"
            << " | Y: {";
        for (auto const& a : nom.accepted)
        {
            oss << " '" << getValueString(a) << "',";
        }
        oss << "}";
    }
    break;
    }

    oss << " }";
    return oss.str();
}

bool
Slot::federatedAccept(StatementPredicate voted, StatementPredicate accepted,
                      std::map<NodeID, SCPEnvelope> const& envs)
{
    // Checks if the nodes that claimed to accept the statement form a
    // v-blocking set
    if (LocalNode::isVBlocking(getLocalNode()->getQuorumSet(), envs, accepted))
    {
        return true;
    }

    // Checks if the set of nodes that accepted or voted for it form a quorum

    auto ratifyFilter =
        [this, &voted, &accepted](SCPStatement const& st) -> bool
    {
        bool res;
        res = accepted(st) || voted(st);
        return res;
    };

    if (LocalNode::isQuorum(
            getLocalNode()->getQuorumSet(), envs,
            std::bind(&Slot::getQuorumSetFromStatement, this, _1),
            ratifyFilter))
    {
        return true;
    }

    return false;
}

bool
Slot::federatedRatify(StatementPredicate voted,
                      std::map<NodeID, SCPEnvelope> const& envs)
{
    return LocalNode::isQuorum(
        getLocalNode()->getQuorumSet(), envs,
        std::bind(&Slot::getQuorumSetFromStatement, this, _1), voted);
}

std::shared_ptr<LocalNode>
Slot::getLocalNode()
{
    return mSCP.getLocalNode();
}
}
