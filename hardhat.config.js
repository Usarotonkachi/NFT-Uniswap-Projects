let secret = require("./secret")

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-tracer");
require('@nomiclabs/hardhat-ethers');


const { API_URL, PRIVATE_KEY, ETHERSCAN_KEY} = process.env;


module.exports = {
  solidity: {
    version: "0.6.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1
      }
    }
  },
  networks: {

    
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/OpNffoTqO3JsYuD3eB6G-Md0XK_-oc-9",
      accounts: [secret.key]  
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s3.binance.org:8545",
      accounts: [secret.key]  
    },
    rinkeby: {
      url: "https://eth-rinkeby.alchemyapi.io/v2/4R2CSUsPXtYbO_oFXi2rj8sQ_YvnWyor",
      accounts: [secret.key]  
    },

    mainnet: {
      url: "https://speedy-nodes-nyc.moralis.io/26e50ab044cfb048e9442a7f/eth/mainnet",
      accounts: [secret.key]
    },

    goerli:{
      url: "https://eth-goerli.g.alchemy.com/v2/fI8Kr1DvRfnk2HVSqmgvE54bzf2u_Tjt",
      accounts: [secret.key]
    }
    
  },
  etherscan: {
      apiKey: "ZUURYZQ7A52XFECR3GJK9QWPV3273TJNFW" //R8EIQMRWTWTYE9D1XX14SMB3FNEHKJFQQN - etherscan
      //FGHT4VSWHKUSGRS6SSZG66NEHKDJYBREAD - polygonscan
      //9F5YSJNC3WQSDUIWXV7AAIQZKSZCUIYMQ2 - bsc
  }
};