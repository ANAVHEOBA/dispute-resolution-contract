const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Dispute Resolution System", function () {
  let disputeResolution;
  let evidence;
  let arbitration;
  let escrow;
  let owner;
  let user1;
  let user2;
  let arbitrator;

  beforeEach(async function () {
    // Get signers
    [owner, user1, user2, arbitrator] = await ethers.getSigners();

    // Deploy contracts
    const Evidence = await ethers.getContractFactory("Evidence");
    evidence = await Evidence.deploy();

    const minimumStake = ethers.utils.parseEther("0.1");
    const Arbitration = await ethers.getContractFactory("Arbitration");
    arbitration = await Arbitration.deploy(minimumStake);

    const Escrow = await ethers.getContractFactory("Escrow");
    escrow = await Escrow.deploy();

    const DisputeResolution = await ethers.getContractFactory("DisputeResolution");
    disputeResolution = await DisputeResolution.deploy(
      escrow.address,
      evidence.address,
      arbitration.address
    );
  });

  describe("Case Creation", function () {
    it("Should create a new case", async function () {
      const tx = await disputeResolution.connect(user1).createCase(
        "Test dispute",
        0 // GENERAL dispute type
      );

      const receipt = await tx.wait();
      const event = receipt.events.find(e => e.event === 'CaseCreated');
      expect(event).to.not.be.undefined;

      const caseDetails = await disputeResolution.getCaseDetails(1);
      expect(caseDetails.creator).to.equal(user1.address);
    });
  });

  describe("Evidence Submission", function () {
    beforeEach(async function () {
      await disputeResolution.connect(user1).createCase(
        "Test dispute",
        0
      );
    });

    it("Should allow evidence submission", async function () {
      const ipfsHash = "QmTest123";
      await disputeResolution.connect(user1).submitEvidence(1, ipfsHash);
      
      // Verify evidence submission through events
      const evidenceList = await evidence.getCaseEvidence(1);
      expect(evidenceList[0].ipfsHash).to.equal(ipfsHash);
    });
  });

  describe("Arbitration", function () {
    beforeEach(async function () {
      // Setup arbitrator
      await arbitration.connect(arbitrator).stakeTokens({
        value: ethers.utils.parseEther("0.1")
      });
    });

    it("Should allow arbitrator assignment", async function () {
      await disputeResolution.connect(user1).createCase(
        "Test dispute",
        0
      );

      await disputeResolution.connect(owner).assignArbitrator(1, arbitrator.address);
      
      const caseDetails = await disputeResolution.getCaseDetails(1);
      expect(caseDetails.assignedArbitrator).to.equal(arbitrator.address);
    });

    it("Should allow decision submission", async function () {
      await disputeResolution.connect(user1).createCase(
        "Test dispute",
        0
      );

      await disputeResolution.connect(owner).assignArbitrator(1, arbitrator.address);
      await arbitration.connect(arbitrator).submitDecision(1, 1); // IN_FAVOR_PARTY_A

      const decision = await arbitration.caseDecisions(1);
      expect(decision).to.equal(1);
    });
  });

  describe("Escrow", function () {
    beforeEach(async function () {
      await disputeResolution.connect(user1).createCase(
        "Test dispute",
        0
      );
    });

    it("Should handle deposits correctly", async function () {
      const depositAmount = ethers.utils.parseEther("1.0");
      await escrow.connect(user1).depositFunds(1, {
        value: depositAmount
      });

      const balance = await escrow.getEscrowBalance(1);
      expect(balance).to.equal(depositAmount);
    });
  });
});