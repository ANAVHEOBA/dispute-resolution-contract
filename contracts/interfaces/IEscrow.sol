// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEscrow {
    // Events
    event FundsDeposited(uint256 indexed caseId, address indexed depositor, uint256 amount);
    event FundsReleased(uint256 indexed caseId, address indexed recipient, uint256 amount);
    event FundsRefunded(uint256 indexed caseId, address indexed recipient, uint256 amount);

    // Functions
    function depositFunds(uint256 caseId) external payable;
    function releaseFunds(uint256 caseId, address payable recipient) external;
    function refundFunds(uint256 caseId) external;
    function getEscrowBalance(uint256 caseId) external view returns (uint256);
    function lockFunds(uint256 caseId) external;
}