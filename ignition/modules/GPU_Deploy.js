const { ethers } = require("hardhat");
require('dotenv').config();

async function main()
{
  const provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  const deployer = new ethers.Wallet(process.env.OWNER_PRIVATE_KEY, provider);
  let helper = "0xcA209dAB3D38e8D77AA4fbCEc53873e9Cff99EC7"; 
  let scheduler = "0xcA209dAB3D38e8D77AA4fbCEc53873e9Cff99EC7"; 
  let nftContract = "0x4e38785dFaE8DF28c69bF8507ebA224259946cfa"; 
  //let gpuProxy = "0x4e38785dFaE8DF28c69bF8507ebA224259946cfa"; 

  const gpuFactory= await ethers.getContractFactory("GPU");
  console.log("Deployer: "+ deployer.address);
  const gpuProxy = await upgrades.deployProxy(
    gpuFactory,
    [
      nftContract,
      69,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      1,
      helper, 
      scheduler,
    ],
    { initializer: "initialize",
        gasPrice: ethers.parseUnits("30", "gwei"),
        // timeout: 180000, // 3 minutes in milliseconds
        // pollingInterval: 5000
     }
  );

  //await gpuProxy.waitForDeployment(); 

  console.log("GPU deployed at:", gpuProxy.target);

  const upgradedQueenStakeFactory = await ethers.getContractFactory("NewQueenStaking"); 
  const upgradedQueenStakeProxy = await upgrades.deployProxy(
    upgradedQueenStakeFactory,
    [
        gpuProxy.target,
        nftContract,
        ethers.parseEther("1000") 
    ],
    { initializer: "initialize",
        gasPrice: ethers.parseUnits("30", "gwei"),
// timeout: 180000, // 3 minutes in milliseconds
// pollingInterval: 5000
     }
  );

  const tx1 = await upgradedQueenStakeProxy.connect(deployer).setUserFunctionStatus(true, 0);
  //await tx1.wait();
  const tx2 = await upgradedQueenStakeProxy.connect(deployer).setUserFunctionStatus(true, 1);
  //await tx2.wait();
  const tx3 = await upgradedQueenStakeProxy.connect(deployer).setUserFunctionStatus(true, 2);
  //await tx3.wait();
  const tx4 = await upgradedQueenStakeProxy.connect(deployer).setUserFunctionStatus(true, 3);
  //await tx4.wait();
  const tx5 = await upgradedQueenStakeProxy.connect(deployer).setUserFunctionStatus(true, 4);
  //await tx5.wait();

  console.log("Upgraded queen deployed at:", upgradedQueenStakeProxy.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});