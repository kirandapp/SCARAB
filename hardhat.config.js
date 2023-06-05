require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config()
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  solidity: "0.8.18",
  networks: {

    bsct: {
      url: process.env.BSCT_URL || "",
      accounts:
        process.env.TEST_PRIVATE_KEY !== undefined ? [process.env.TEST_PRIVATE_KEY] : [],
    },

    hardhat: {
      chainId: 31337,
      forking: {
        url: `${ process.env.BSC_MAIINETFORK_RPC_URL_QUICKNODE }`,
        blockNumber: 14390000,
      }
    },
  },
  settings: {
    optimizer: {
      enabled: true,
      viaIR: true,
      runs: 200,
    },
  },
  allowUnlimitedContractSize: true,

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
