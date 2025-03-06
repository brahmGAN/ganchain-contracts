const { ethers } = require("hardhat");
require('dotenv').config();

async function main()
{
  const provider = new ethers.JsonRpcProvider(process.env.GPU_RPC);
  const deployer = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);

  const buyBackFactory= await ethers.getContractFactory("BuyBack",deployer);
  console.log("Deployer: "+ deployer.address);
  const buyBack = await buyBackFactory.deploy();

  await buyBack.waitForDeployment();

  console.log("BuyBAck deployed at:", buyBack.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});