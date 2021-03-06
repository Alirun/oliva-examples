const { accounts, contract, web3 } = require('@openzeppelin/test-environment')
const { expectRevert } = require('@openzeppelin/test-helpers')
const { assert } = require('chai')
const { BigNumber } = require('ethers')
const { ethers } = require('hardhat')
const erc20ABI = require('../../utils/erc20abi.json')
const [ owner ] = accounts

const OlivePriceChainlinkOracleId = contract.fromArtifact('OlivePriceChainlinkOracleId')
const OracleAggregator = contract.fromArtifact('OracleAggregator')


const OpiumOracleAggregator = '0xe1Fd20231512611a5025Dec275464208070B985f'
const EMERGENCY_PERIOD = 60

async function fillWithLink(owner, priceOracle) {
  let linkAddress = await priceOracle.chainlinkTokenAddress()
  let link = new web3.eth.Contract(erc20ABI,linkAddress)
  let tx = await link.transfer(priceOracle.address, web3.utils.toWei('0.1')).send({ from: owner })
  console.log(tx)
}

describe('OlivePriceChainlinkOracleId', function () {
  before(async () => {
    this.oracleId = await OlivePriceChainlinkOracleId.new(OpiumOracleAggregator, EMERGENCY_PERIOD, { from: owner })
    this.oracleAggregator = await OracleAggregator.at(OpiumOracleAggregator)
    console.log(owner)
    await fillWithLink(owner, this.oracleId)

    this.now = ~~(Date.now() / 1e3) // timestamp now
    this.past = ~~(Date.now() / 1e3) - 60 // timestamp 60 seconds ago

    this.queryId = web3.utils.soliditySha3(this.oracleId.address, this.now)
    this.queryIdPast = web3.utils.soliditySha3(this.oracleId.address, this.past)
  })

  it('should be able to request price from Chainlink', async () => {
    const requestID = await this.oracleId.requestPrice().send()

    assert.exists(requestID, 'Price was not requested correctly')
    const price = await this.oracleId.price.call()
    console.log(price.toString())
    assert.notEqual(price.toString(),'0')
  })

  it('should be able to fulfill request from Chainlink', async () => {
    await this.oracleId.fulfill('123', '234').send()
    let price = this.oracleId.price.call()


    assert.equal(price,new BigNumber('234'), 'Price was not requested correctly')
  })



  it('should request price via Opium OracleAggregator', async () => {
    await this.oracleAggregator.fetchData(this.oracleId.address, this.now)
    const requested = await this.oracleAggregator.dataRequested.call(this.oracleId.address, this.now)
    assert.isTrue(requested, 'Data was not requested')
  })

  it('should provide price from Chainlink to Opium OracleAggregator', async () => {
    await this.oracleId._callback(this.queryId)

    const hasData = await this.oracleAggregator.hasData.call(this.oracleId.address, this.now)
    const data = await this.oracleAggregator.getData.call(this.oracleId.address, this.now)

    assert.isTrue(hasData, 'Data was not provided')
  })

  it('should not allow to call emergencyCallback after data are provided', async () => {
    await expectRevert.unspecified(
      this.oracleId.emergencyCallback(this.queryId, '12345678', { from: owner })
    )
  })

  it('should allow to call emergencyCallback', async () => {
    await this.oracleAggregator.fetchData(this.oracleId.address, this.past)

    const customResult = '12345678'

    await this.oracleId.emergencyCallback(this.queryIdPast, customResult, { from: owner })

    const hasData = await this.oracleAggregator.hasData.call(this.oracleId.address, this.past)
    const data = await this.oracleAggregator.getData.call(this.oracleId.address, this.past)

    assert.isTrue(hasData, 'Data was not provided')
    assert.equal(data.toString(), customResult.toString(), 'Data do not match')
  })
})
