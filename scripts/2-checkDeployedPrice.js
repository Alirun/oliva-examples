// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const web3 = hre.web3;
const oracleContractData = require('../artifacts/contracts/oracles/chainlink/OlivePriceChainlinkOracleId.sol/OlivePriceChainlinkOracleId.json')
let deployed = '0xaD3643d0B1B9E3A433A267B4bbB9CE280B018f25'

async function main() {
  let accounts = await web3.eth.getAccounts()
  let owner = accounts[0]
  // Rinkeby
  const OracleContract = new web3.eth.Contract(oracleContractData.abi, deployed)


  var price = await OracleContract.methods.price().call()
  console.log('price', price)



}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });