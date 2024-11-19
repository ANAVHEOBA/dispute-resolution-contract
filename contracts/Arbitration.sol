// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IArbitration.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Arbitration is IArbitration, ReentrancyGuard, Ownable {
    // State Variables
    struct ArbitratorInfo {
        uint256 stakedAmount;
        uint256 casesHandled;
        bool isActive;
        mapping(uint256 => bool) assignedCases;
    }
    
    mapping(address => ArbitratorInfo) public arbitrators;
    mapping(uint256 => Decision) public caseDecisions;
    address public disputeResolutionContract;
    uint256 public minimumStake;
    
    // Modifiers
    modifier onlyDisputeResolution() {
        require(msg.sender == disputeResolutionContract, "Only dispute resolution contract");
        _;
    }

    modifier onlyActiveArbitrator() {
        require(arbitrators[msg.sender].isActive, "Not an active arbitrator");
        _;
    }

    modifier validCase(uint256 caseId) {
        require(arbitrators[msg.sender].assignedCases[caseId], "Not assigned to this case");
        require(caseDecisions[caseId] == Decision.PENDING, "Decision already submitted");
        _;
    }

    // Constructor
    constructor(uint256 _minimumStake) {
        disputeResolutionContract = msg.sender;
        minimumStake = _minimumStake;
    }

    // External Functions
    function assignArbitrator(uint256 caseId, address arbitrator) 
        external 
        override 
        onlyDisputeResolution 
    {
        require(arbitrators[arbitrator].isActive, "Arbitrator not active");
        require(!arbitrators[arbitrator].assignedCases[caseId], "Already assigned");

        arbitrators[arbitrator].assignedCases[caseId] = true;
        emit ArbitratorAssigned(caseId, arbitrator);
    }

    function submitDecision(uint256 caseId, Decision decision) 
        external 
        override 
        onlyActiveArbitrator 
        validCase(caseId) 
    {
        require(decision != Decision.PENDING, "Invalid decision");
        
        caseDecisions[caseId] = decision;
        arbitrators[msg.sender].casesHandled++;
        
        emit DecisionSubmitted(caseId, msg.sender, decision);
    }

    function stakeTokens(uint256 amount) 
        external 
        override 
        nonReentrant 
    {
        require(amount >= minimumStake, "Stake below minimum");
        
        arbitrators[msg.sender].stakedAmount += amount;
        if (!arbitrators[msg.sender].isActive && arbitrators[msg.sender].stakedAmount >= minimumStake) {
            arbitrators[msg.sender].isActive = true;
        }
        
        emit ArbitratorStaked(msg.sender, amount);
    }

    function withdrawStake(uint256 amount) 
        external 
        override 
        nonReentrant 
    {
        require(arbitrators[msg.sender].stakedAmount >= amount, "Insufficient stake");
        
        uint256 remainingStake = arbitrators[msg.sender].stakedAmount - amount;
        if (remainingStake < minimumStake) {
            arbitrators[msg.sender].isActive = false;
        }
        
        arbitrators[msg.sender].stakedAmount = remainingStake;
        payable(msg.sender).transfer(amount);
    }

    function getArbitratorStatus(address arbitrator) 
        external 
        view 
        override 
        returns (
            uint256 stakedAmount,
            uint256 casesHandled,
            bool isActive
        ) 
    {
        ArbitratorInfo storage info = arbitrators[arbitrator];
        return (
            info.stakedAmount,
            info.casesHandled,
            info.isActive
        );
    }

    // Admin Functions
    function updateMinimumStake(uint256 newMinimum) 
        external 
        onlyOwner 
    {
        minimumStake = newMinimum;
    }

    function updateDisputeResolutionContract(address newAddress) 
        external 
        onlyOwner 
    {
        require(newAddress != address(0), "Invalid address");
        disputeResolutionContract = newAddress;
    }

    // Internal helper functions
    function _deactivateArbitrator(address arbitrator) internal {
        arbitrators[arbitrator].isActive = false;
    }

    // Receive function to accept ETH for staking
    receive() external payable {
        stakeTokens(msg.value);
    }
}