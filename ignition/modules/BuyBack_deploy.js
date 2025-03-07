const { ethers } = require("hardhat");
require('dotenv').config();

async function main()
{

  const buyBackFactory= await ethers.getContractFactory("BuyBack");
  const buyBack = await buyBackFactory.deploy();

  await buyBack.waitForDeployment();

  console.log("BuyBAck deployed at:", buyBack.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});