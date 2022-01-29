const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  // const deployerAddress = deployer.address;
  const deployerAddress = await deployer.getAddress();
  console.log('Deploying Vanity Contract with address:', deployerAddress);

  const Vanity = await hre.ethers.getContractFactory("Vanity");

  const Vanity_name = await Vanity.deploy(86544564, 0.001);
  console.log('Vanity contract deployed at', Vanity_name.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
