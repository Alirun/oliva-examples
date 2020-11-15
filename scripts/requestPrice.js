// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const web3 = hre.web3;
const oracleContractData = require('../artifacts/contracts/oracles/chainlink/OlivePriceChainlinkOracleId.sol/OlivePriceChainlinkOracleId.json')

//Rinkeby


let deployedOracleAddress = '0x9eD34492F812a2C2a2ce37c481b2D0D51f6d33bc'

async function main() {
  let accounts = await web3.eth.getAccounts()
  let owner = accounts[0]
  // Rinkeby
  const OracleContract = new web3.eth.Contract(oracleContractData.abi, deployedOracleAddress)

  console.log('Oracle at: ',deployedOracleAddress)


  console.log('Requesting price...')
  var res = await OracleContract.methods.requestPrice(~~(Date.now() / 1e3)).send({
    from: owner,
    gas: 5000000
  })
  console.log(res)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });