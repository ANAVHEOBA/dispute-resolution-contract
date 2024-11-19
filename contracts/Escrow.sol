// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IEscrow.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Escrow is IEscrow, ReentrancyGuard, Ownable {
    // State Variables
    struct EscrowAccount {
        uint256 amount;
        bool locked;
        mapping(address => uint256) deposits;
    }
    
    mapping(uint256 => EscrowAccount) public escrowAccounts;
    address public disputeResolutionContract;
    
    // Modifiers
    modifier onlyDisputeResolution() {
        require(msg.sender == disputeResolutionContract, "Only dispute resolution contract");
        _;
    }
    
    modifier caseNotLocked(uint256 caseId) {
        require(!escrowAccounts[caseId].locked, "Case is locked");
        _;
    }

    modifier sufficientBalance(uint256 caseId, uint256 amount) {
        require(escrowAccounts[caseId].amount >= amount, "Insufficient balance");
        _;
    }
    
    // Constructor
    constructor() {
        disputeResolutionContract = msg.sender;
    }

    // External Functions
    function depositFunds(uint256 caseId) 
        external 
        payable 
        override 
        caseNotLocked(caseId) 
    {
        require(msg.value > 0, "Must deposit some funds");
        
        EscrowAccount storage account = escrowAccounts[caseId];
        account.amount += msg.value;
        account.deposits[msg.sender] += msg.value;
        
        emit FundsDeposited(caseId, msg.sender, msg.value);
    }

    function releaseFunds(uint256 caseId, address payable recipient) 
        external 
        override 
        onlyDisputeResolution 
        sufficientBalance(caseId, escrowAccounts[caseId].amount) 
    {
        uint256 amount = escrowAccounts[caseId].amount;
        escrowAccounts[caseId].amount = 0;
        
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsReleased(caseId, recipient, amount);
    }

    function refundFunds(uint256 caseId) 
        external 
        override 
        onlyDisputeResolution 
        caseNotLocked(caseId) 
    {
        uint256 deposited = escrowAccounts[caseId].deposits[msg.sender];
        require(deposited > 0, "No funds to refund");
        
        escrowAccounts[caseId].deposits[msg.sender] = 0;
        escrowAccounts[caseId].amount -= deposited;
        
        (bool success, ) = payable(msg.sender).call{value: deposited}("");
        require(success, "Transfer failed");
        
        emit FundsRefunded(caseId, msg.sender, deposited);
    }

    function lockFunds(uint256 caseId) 
        external 
        override 
        onlyDisputeResolution 
    {
        require(!escrowAccounts[caseId].locked, "Already locked");
        escrowAccounts[caseId].locked = true;
    }

    function getEscrowBalance(uint256 caseId) 
        external 
        view 
        override 
        returns (uint256) 
    {
        return escrowAccounts[caseId].amount;
    }

    // Additional utility functions
    function getDepositorBalance(uint256 caseId, address depositor) 
        external 
        view 
        returns (uint256) 
    {
        return escrowAccounts[caseId].deposits[depositor];
    }

    function isLocked(uint256 caseId) 
        external 
        view 
        returns (bool) 
    {
        return escrowAccounts[caseId].locked;
    }

    // Emergency functions
    function updateDisputeResolutionContract(address _newAddress) 
        external 
        onlyOwner 
    {
        require(_newAddress != address(0), "Invalid address");
        disputeResolutionContract = _newAddress;
    }

    function emergencyWithdraw(uint256 caseId, address payable recipient) 
        external 
        onlyOwner 
    {
        uint256 amount = escrowAccounts[caseId].amount;
        escrowAccounts[caseId].amount = 0;
        
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit FundsReleased(caseId, recipient, amount);
    }

    // Receive function to accept ETH
    receive() external payable {
        revert("Use depositFunds function to deposit");
    }
}