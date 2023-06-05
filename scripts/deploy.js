const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  //   console.log(Deploying  Contracts with the account: ${deployer.address});
  const Scarab = await ethers.getContractFactory("Scarab");
  console.log("\nDeploying Scarab Token...");
  const scarab = await Scarab.deploy();
  await scarab.deployed();


  const ScarabNft = await ethers.getContractFactory("ScarabNft");
  console.log("\nDeploying ScarabNft...");
  const scarabNft = await ScarabNft.deploy();
  await scarabNft.deployed();


  const Treasury = await ethers.getContractFactory("Treasury");
  console.log("\nDeploying Treasury...");
  const treasury = await Treasury.deploy();
  await treasury.deployed();


  const Dao = await ethers.getContractFactory("Dao");
  console.log("\nDeploying Dao...");
  const dao = await Dao.deploy();
  await dao.deployed();


  const AddressContract = await ethers.getContractFactory("AddressContract");
  console.log("\nDeploying AddressContract...");
  const addressContract = await AddressContract.deploy();
  await addressContract.deployed(); 

  console.log("contracts deployed at: ", scarab.address, scarabNft.address, treasury.address, dao.address, addressContract.address);

  await addressContract.setContractAddresses(dao.address,treasury.address,scarabNft.address,scarab.address);

  await scarab.setContractAddresses(addressContract.address);
  await scarabNft.setContractAddresses(addressContract.address);
  await treasury.setContractAddresses(addressContract.address);
  await dao.setContractAddresses(addressContract.address);

  await scarab.setWhitelistAddress(treasury.address);
  await scarab.setWhitelistAddress(scarabNft.address);

}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});