// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbitration {
    // Enums
    enum Decision { PENDING, IN_FAVOR_PARTY_A, IN_FAVOR_PARTY_B, SPLIT }

    // Events
    event ArbitratorAssigned(uint256 indexed caseId, address indexed arbitrator);
    event DecisionSubmitted(uint256 indexed caseId, address indexed arbitrator, Decision decision);
    event ArbitratorStaked(address indexed arbitrator, uint256 amount);

    // Functions
    function assignArbitrator(uint256 caseId, address arbitrator) external;
    function submitDecision(uint256 caseId, Decision decision) external;
    function stakeTokens(uint256 amount) external;
    function withdrawStake(uint256 amount) external;
    function getArbitratorStatus(address arbitrator) external view returns (
        uint256 stakedAmount,
        uint256 casesHandled,
        bool isActive
    );
}