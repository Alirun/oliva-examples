// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const web3 = hre.web3;
const oracleContractData = require('../artifacts/contracts/oracles/chainlink/OlivePriceChainlinkOracleId.sol/OlivePriceChainlinkOracleId.json')
const erc20ABI = require('../test/utils/erc20abi.json')

//Rinkeby
const OpiumOracleAggregator = '0xe1Fd20231512611a5025Dec275464208070B985f'
const EMERGENCY_PERIOD = 60

let linkAddress = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709'
let deployedOracleAddress = '0x9eD34492F812a2C2a2ce37c481b2D0D51f6d33bc'

async function main() {
  let accounts = await web3.eth.getAccounts()
  let owner = accounts[0]
  // Rinkeby
  const OracleContract = new web3.eth.Contract(oracleContractData.abi, deployedOracleAddress)

  console.log('Oracle at: ',deployedOracleAddress)

  console.log('withdraw link...')
  const LinkContract = new web3.eth.Contract(erc20ABI, linkAddress)


  await OracleContract.methods.withdrawLink().send({
    from: owner
  })
  contractBalance = await LinkContract.methods.balanceOf(deployedOracleAddress).call()
  console.log('balance after withdraw', contractBalance)



}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });