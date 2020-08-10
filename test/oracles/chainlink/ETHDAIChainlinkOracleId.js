const { accounts, contract, web3 } = require('@openzeppelin/test-environment')
const { expectRevert } = require('@openzeppelin/test-helpers')
const { assert } = require('chai')

const [ owner ] = accounts

const ETHDAIChainlinkOracleId = contract.fromArtifact('ETHDAIChainlinkOracleId')
const OracleAggregator = contract.fromArtifact('OracleAggregator')

const ETHDAIAggregator = '0x037E8F2125bF532F3e228991e051c8A7253B642c'
const OpiumOracleAggregator = '0xB69890912E40A7849fCA058bb118Cfe7d70932c4'
const EMERGENCY_PERIOD = 60

describe('ETHDAIChainlinkOracleId', function () {
  before(async () => {
    this.oracleId = await ETHDAIChainlinkOracleId.new(ETHDAIAggregator, OpiumOracleAggregator, EMERGENCY_PERIOD, { from: owner })
    this.oracleAggregator = await OracleAggregator.at(OpiumOracleAggregator)

    this.now = ~~(Date.now() / 1e3) // timestamp now
    this.past = ~~(Date.now() / 1e3) - 60 // timestamp 60 seconds ago

    this.queryId = web3.utils.soliditySha3(this.oracleId.address, this.now)
    this.queryIdPast = web3.utils.soliditySha3(this.oracleId.address, this.past)
  })

  it('should be able to return price from Chainlink', async () => {
    const price = await this.oracleId.getLatestPrice()

    assert.exists(price, 'Price was not returned correctly')
  })

  it('should be able to return reversed price', async () => {
    const reversedPrice = await this.oracleId.getReversedLatestPrice()
    this.reversedPrice = reversedPrice

    assert.exists(reversedPrice, 'Reversed price was not returned correctly')
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
    assert.equal(data.toString(), this.reversedPrice.toString(), 'Data do not match')
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
