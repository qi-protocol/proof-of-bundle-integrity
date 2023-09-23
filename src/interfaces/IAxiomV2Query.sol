// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./IAxiomV2HeaderVerifier.sol";

uint256 constant PROOF_GAS = 500_000;
uint256 constant AXIOM_QUERY_FEE = 0.005 ether;

interface IAxiomV2Query {
    /// @notice States of an on-chain query
    /// @param  Inactive The query has not been made or was refunded.
    /// @param  Active The query has been requested, but not fulfilled.
    /// @param  Fulfilled The query was successfully fulfilled.
    enum AxiomQueryState {
        Inactive,
        Active,
        Fulfilled
    }

    /// @notice Stores metadata about a query
    /// @param  state The state of the query.
    /// @param  deadlineBlockNumber The deadline (in block number) after which a refund may be granted.
    /// @param  refundee The address funds should be returned to if the query is not fulfilled.
    struct AxiomQueryMetadata {
        AxiomQueryState state;
        uint32 deadlineBlockNumber;
        bytes32 querySchema;
        uint8 resultLen;
        address callerAddr;
        address callbackAddr;
        bytes4 callbackFunctionSelector;
        bytes32 callbackExtraDataHash;
    }

    struct AxiomProofData {
        uint64 sourceChainId;
        bytes32 dataResultsRoot;
        bytes32 dataResultsPoseidonRoot;
        bytes32 computeResultsHash;
        bytes32 queryHash;
        bytes32 querySchema;
        bytes32 historicalMMRKeccak;
        bytes32 recentMMRKeccak;
        bytes32 aggregateVkeyHash;
        address payee;
    }

    struct AxiomProofCallbackData {
        uint64 sourceChainId;
        address payee;
        bytes32 queryHash;
        bytes32 querySchema;
        bytes32 computeResultsHash;
    }

    struct AxiomV2ComputeQuery {
        uint8 k;
        bytes32[] vkey;
        bytes computeProof;
    }

    struct AxiomV2Callback {
        address callbackAddr;
        bytes4 callbackFunctionSelector;
        uint8 resultLen;
        bytes callbackExtraData;
    }
}
