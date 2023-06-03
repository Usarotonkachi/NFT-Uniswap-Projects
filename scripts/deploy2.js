const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const GrandApeGang = await ethers.getContractFactory("BEP20Token");
  const grandApeGang = await GrandApeGang.deploy();

  await grandApeGang.deployed();
  
  console.log("MakedCharged deployed to address: ", grandApeGang.address);
  console.log("MakedCharged deployed to block: ", await hre.ethers.provider.getBlockNumber());
  console.log("MakedCharged owner is: ", await (grandApeGang.provider.getSigner() ).getAddress() );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });