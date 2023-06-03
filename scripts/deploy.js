const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const GrandApeGang = await ethers.getContractFactory("newTask");
  const grandApeGang = await GrandApeGang.deploy("0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D", "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f");

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