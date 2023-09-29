import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-etherscan";

import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";

dotenv.config();

const API_URL = `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defaultNetwork: "polygon",
  networks: {
    polygon: {
      chainId: 137,
      url: API_URL,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gas: "auto",
      gasPrice: "auto",
    },
  },
  etherscan: {
    apiKey: `${process.env.POLYGONSCAN_KEY}`,
  },
};

export default config;
