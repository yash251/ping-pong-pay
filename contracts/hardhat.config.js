require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

const privateKeys = process.env.PRIVATE_KEYS || '';

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
  networks: {
    localhost: {},
    sepolia: {
      url: 'https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}',
      accounts: privateKeys.split(','),
    }
  }
};
