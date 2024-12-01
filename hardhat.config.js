require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10,
      },
      viaIR: true,
    },  
  },
  allowUnlimitedContractSize: true,
  // networks: {
  //   sepolia: {
  //     url: `${process.env.SEPOLIA_RPC_URL}`,
  //     accounts: [`${process.env.DEPLOYER_PRIVATE_KEY}`],
  //   }, 
  // }
};