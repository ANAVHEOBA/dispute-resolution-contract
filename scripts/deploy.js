const hre = require("hardhat");

async function main() {
  console.log("Starting deployment...");

  // Deploy Evidence contract first
  const Evidence = await hre.ethers.getContractFactory("Evidence");
  const evidence = await Evidence.deploy();
  await evidence.deployed();
  console.log("Evidence deployed to:", evidence.address);

  // Deploy Arbitration contract
  const minimumStake = hre.ethers.utils.parseEther("0.1"); // 0.1 ETH minimum stake
  const Arbitration = await hre.ethers.getContractFactory("Arbitration");
  const arbitration = await Arbitration.deploy(minimumStake);
  await arbitration.deployed();
  console.log("Arbitration deployed to:", arbitration.address);

  // Deploy Escrow contract
  const Escrow = await hre.ethers.getContractFactory("Escrow");
  const escrow = await Escrow.deploy();
  await escrow.deployed();
  console.log("Escrow deployed to:", escrow.address);

  // Deploy main DisputeResolution contract
  const DisputeResolution = await hre.ethers.getContractFactory("DisputeResolution");
  const disputeResolution = await DisputeResolution.deploy(
    escrow.address,
    evidence.address,
    arbitration.address
  );
  await disputeResolution.deployed();
  console.log("DisputeResolution deployed to:", disputeResolution.address);

  // Verify contracts on Etherscan
  if (hre.network.name !== "hardhat") {
    console.log("Verifying contracts...");
    await hre.run("verify:verify", {
      address: disputeResolution.address,
      constructorArguments: [escrow.address, evidence.address, arbitration.address],
    });
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });