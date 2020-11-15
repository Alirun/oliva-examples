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

async function main() {
  let accounts = await web3.eth.getAccounts()
  let owner = accounts[0]
  // Rinkeby
  const OracleContract = new web3.eth.Contract(oracleContractData.abi)
  let oracleId = await OracleContract.deploy({
    data: oracleContractData.bytecode,
    arguments: [
      OpiumOracleAggregator,
      EMERGENCY_PERIOD
    ]
  })
  .send({
      from: owner,
      gas: 5000000
  })
  console.log('Deployed at: ',oracleId.options.address)

  console.log('funding contract with link')
  const LinkContract = new web3.eth.Contract(erc20ABI, linkAddress)
  await LinkContract.methods.transfer(oracleId.options.address, web3.utils.toWei('1')).send({
    from: owner
  })

  var contractBalance = await LinkContract.methods.balanceOf(oracleId.options.address).call()
  console.log('balance before requesting', contractBalance)

  console.log('Requesting price...')
  var res = await oracleId.methods.requestPrice(~~(Date.now() / 1e3)).send({
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