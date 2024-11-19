// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IDisputeResolution.sol";
import "./Escrow.sol";
import "./Evidence.sol";
import "./Arbitration.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DisputeResolution is IDisputeResolution, Ownable, ReentrancyGuard {
    // State Variables
    struct Case {
        address creator;
        DisputeType disputeType;
        CaseStatus status;
        uint256 createdAt;
        address[] parties;
        address assignedArbitrator;
    }
    
    mapping(uint256 => Case) public cases;
    uint256 private nextCaseId;
    
    Escrow public escrow;
    Evidence public evidence;
    Arbitration public arbitration;
    
    // Modifiers
    modifier caseExists(uint256 caseId) {
        require(cases[caseId].creator != address(0), "Case does not exist");
        _;
    }

    modifier onlyParticipant(uint256 caseId) {
        bool isParticipant = false;
        for (uint i = 0; i < cases[caseId].parties.length; i++) {
            if (cases[caseId].parties[i] == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "Not a case participant");
        _;
    }

    // Constructor
    constructor(
        address _escrowAddress,
        address _evidenceAddress,
        address _arbitrationAddress
    ) {
        escrow = Escrow(_escrowAddress);
        evidence = Evidence(_evidenceAddress);
        arbitration = Arbitration(_arbitrationAddress);
        nextCaseId = 1;
    }

    // Core functions implementing IDisputeResolution interface
    function createCase(
        string calldata description,
        DisputeType disputeType
    ) external override returns (uint256) {
        uint256 caseId = nextCaseId++;
        
        address[] memory parties = new address[](1);
        parties[0] = msg.sender;
        
        cases[caseId] = Case({
            creator: msg.sender,
            disputeType: disputeType,
            status: CaseStatus.PENDING,
            createdAt: block.timestamp,
            parties: parties,
            assignedArbitrator: address(0)
        });

        emit CaseCreated(caseId, msg.sender, disputeType);
        return caseId;
    }

    function submitEvidence(
        uint256 caseId,
        string calldata evidenceHash
    ) external override caseExists(caseId) onlyParticipant(caseId) {
        require(
            cases[caseId].status != CaseStatus.RESOLVED &&
            cases[caseId].status != CaseStatus.CANCELLED,
            "Case is no longer active"
        );
        
        emit EvidenceSubmitted(caseId, msg.sender, evidenceHash);
    }

    function updateCaseStatus(
        uint256 caseId,
        CaseStatus newStatus
    ) external override caseExists(caseId) {
        require(
            msg.sender == owner() || 
            msg.sender == cases[caseId].assignedArbitrator,
            "Unauthorized"
        );
        
        cases[caseId].status = newStatus;
        emit CaseStatusUpdated(caseId, newStatus);
    }

    function getCaseDetails(
        uint256 caseId
    ) external view override returns (
        address creator,
        DisputeType disputeType,
        CaseStatus status,
        uint256 createdAt
    ) {
        Case storage c = cases[caseId];
        return (
            c.creator,
            c.disputeType,
            c.status,
            c.createdAt
        );
    }

    // Additional helper functions
    function addPartyToCase(
        uint256 caseId,
        address party
    ) external caseExists(caseId) {
        require(
            msg.sender == owner() || 
            msg.sender == cases[caseId].creator,
            "Unauthorized"
        );
        cases[caseId].parties.push(party);
    }

    function assignArbitratorToCase(
        uint256 caseId,
        address arbitrator
    ) external onlyOwner caseExists(caseId) {
        require(cases[caseId].assignedArbitrator == address(0), "Arbitrator already assigned");
        cases[caseId].assignedArbitrator = arbitrator;
        cases[caseId].status = CaseStatus.ACTIVE;
        
        emit CaseStatusUpdated(caseId, CaseStatus.ACTIVE);
    }

    function getParties(
        uint256 caseId
    ) external view caseExists(caseId) returns (address[] memory) {
        return cases[caseId].parties;
    }

    // Emergency functions
    function emergencyPause() external onlyOwner {
        _pause();
    }

    function emergencyUnpause() external onlyOwner {
        _unpause();
    }
}