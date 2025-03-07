require("@nomicfoundation/hardhat-toolbox");
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */

// Using a hardcoded solution to avoid GitHub actions issues
const DEPLOYER_PRIVATE_KEY =
  process.env.OWNER_PRIVATE_KEY ||
  "";

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
  networks: {
    sepolia: {
      url: `${process.env.SEPOLIA_RPC_URL}`,
      accounts: [`${DEPLOYER_PRIVATE_KEY}`],
    }, 
    gpu: {
      url: `${process.env.GPU_RPC}`,
      accounts: [`${DEPLOYER_PRIVATE_KEY}`],
    }, 
  },
  gasReporter: {
    enabled: true,
  },
};