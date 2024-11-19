// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Evidence is Ownable {
    // State Variables
    struct EvidenceDetails {
        string ipfsHash;
        address submitter;
        uint256 timestamp;
        bool verified;
    }
    
    mapping(uint256 => EvidenceDetails[]) public caseEvidence;
    address public disputeResolutionContract;
    
    // Events
    event EvidenceAdded(uint256 indexed caseId, string ipfsHash, address submitter);
    event EvidenceVerified(uint256 indexed caseId, uint256 evidenceIndex);
    
    // Errors
    error InvalidCaseId();
    error InvalidEvidenceIndex();
    error UnauthorizedSubmitter();
    error EmptyIPFSHash();
    error EvidenceAlreadyVerified();
    
    // Modifiers
    modifier onlyDisputeResolution() {
        require(msg.sender == disputeResolutionContract, "Only dispute resolution contract");
        _;
    }

    modifier validIPFSHash(string memory ipfsHash) {
        require(bytes(ipfsHash).length > 0, "IPFS hash cannot be empty");
        _;
    }
    
    // Constructor
    constructor() {
        disputeResolutionContract = msg.sender;
    }

    /**
     * @dev Submits new evidence for a case
     * @param caseId The ID of the case
     * @param ipfsHash The IPFS hash of the evidence
     */
    function submitEvidence(
        uint256 caseId,
        string memory ipfsHash
    ) external validIPFSHash(ipfsHash) {
        EvidenceDetails memory newEvidence = EvidenceDetails({
            ipfsHash: ipfsHash,
            submitter: msg.sender,
            timestamp: block.timestamp,
            verified: false
        });
        
        caseEvidence[caseId].push(newEvidence);
        
        emit EvidenceAdded(caseId, ipfsHash, msg.sender);
    }

    /**
     * @dev Verifies submitted evidence
     * @param caseId The ID of the case
     * @param evidenceIndex The index of the evidence in the case's evidence array
     */
    function verifyEvidence(
        uint256 caseId,
        uint256 evidenceIndex
    ) external onlyDisputeResolution {
        if (evidenceIndex >= caseEvidence[caseId].length) revert InvalidEvidenceIndex();
        if (caseEvidence[caseId][evidenceIndex].verified) revert EvidenceAlreadyVerified();
        
        caseEvidence[caseId][evidenceIndex].verified = true;
        
        emit EvidenceVerified(caseId, evidenceIndex);
    }

    /**
     * @dev Gets all evidence for a specific case
     * @param caseId The ID of the case
     */
    function getCaseEvidence(uint256 caseId) external view returns (EvidenceDetails[] memory) {
        return caseEvidence[caseId];
    }

    /**
     * @dev Gets specific evidence details
     * @param caseId The ID of the case
     * @param evidenceIndex The index of the evidence
     */
    function getEvidenceDetails(
        uint256 caseId,
        uint256 evidenceIndex
    ) external view returns (EvidenceDetails memory) {
        if (evidenceIndex >= caseEvidence[caseId].length) revert InvalidEvidenceIndex();
        return caseEvidence[caseId][evidenceIndex];
    }

    /**
     * @dev Gets the count of evidence for a case
     * @param caseId The ID of the case
     */
    function getEvidenceCount(uint256 caseId) external view returns (uint256) {
        return caseEvidence[caseId].length;
    }

    /**
     * @dev Updates the dispute resolution contract address
     * @param newAddress The new address
     */
    function updateDisputeResolutionContract(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid address");
        disputeResolutionContract = newAddress;
    }

    /**
     * @dev Checks if evidence exists and is verified
     * @param caseId The ID of the case
     * @param evidenceIndex The index of the evidence
     */
    function isEvidenceVerified(
        uint256 caseId,
        uint256 evidenceIndex
    ) external view returns (bool) {
        if (evidenceIndex >= caseEvidence[caseId].length) revert InvalidEvidenceIndex();
        return caseEvidence[caseId][evidenceIndex].verified;
    }
}