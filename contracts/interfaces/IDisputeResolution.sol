// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDisputeResolution {
    // Enums
    enum CaseStatus { PENDING, ACTIVE, IN_REVIEW, RESOLVED, CANCELLED }
    enum DisputeType { GENERAL, FINANCIAL, SERVICE, PROPERTY }

    // Events
    event CaseCreated(uint256 indexed caseId, address indexed creator, DisputeType disputeType);
    event CaseStatusUpdated(uint256 indexed caseId, CaseStatus newStatus);
    event EvidenceSubmitted(uint256 indexed caseId, address indexed submitter, string evidenceHash);
    event ResolutionProposed(uint256 indexed caseId, address indexed arbitrator);

    // Core Functions
    function createCase(string calldata description, DisputeType disputeType) external returns (uint256);
    function submitEvidence(uint256 caseId, string calldata evidenceHash) external;
    function updateCaseStatus(uint256 caseId, CaseStatus newStatus) external;
    function getCaseDetails(uint256 caseId) external view returns (
        address creator,
        DisputeType disputeType,
        CaseStatus status,
        uint256 createdAt
    );
}