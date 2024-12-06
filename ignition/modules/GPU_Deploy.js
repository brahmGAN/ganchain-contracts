// const { ethers } = require("hardhat");
// require('dotenv').config();

// async function main()
// {
//   let helper = "0xcA209dAB3D38e8D77AA4fbCEc53873e9Cff99EC7"; 
//   let scheduler = "0xcA209dAB3D38e8D77AA4fbCEc53873e9Cff99EC7"; 
//   let nftContract = "0x4e38785dFaE8DF28c69bF8507ebA224259946cfa"; 
//   const gpuFactory= await ethers.getContractFactory("GPU");
//   const gpuProxy = await upgrades.deployProxy(
//     gpuFactory,
//     [
//       nftContract,
//       69,
//       1,
//       1,
//       1,
//       1,
//       1,
//       1,
//       1,
//       1,
//       1,
//       helper, 
//       scheduler,
//     ],
//     { initializer: "initialize" },
//   );

//   console.log("GPU deployed at:", gpuProxy.target);
// }

// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// });