const { accounts, contract, web3 } = require('@openzeppelin/test-environment')
const { expectRevert } = require('@openzeppelin/test-helpers')
const { assert } = require('chai')

const [ owner, thirdparty ] = accounts

const RawOracleId = contract.fromArtifact('RawOracleId')
const OracleAggregator = contract.fromArtifact('OracleAggregator')

const OpiumOracleAggregator = '0xB69890912E40A7849fCA058bb118Cfe7d70932c4'

describe('RawOracleId', function () {
  before(async () => {
    this.oracleId = await RawOracleId.new(OpiumOracleAggregator, { from: owner })
    this.oracleAggregator = await OracleAggregator.at(OpiumOracleAggregator)

    this.now = ~~(Date.now() / 1e3) // timestamp now

    this.queryId = web3.utils.soliditySha3(this.oracleId.address, this.now)
  })

  it('should request price via Opium OracleAggregator', async () => {
    await this.oracleAggregator.fetchData(this.oracleId.address, this.now)
    const requested = await this.oracleAggregator.dataRequested.call(this.oracleId.address, this.now)
    assert.isTrue(requested, 'Data was not requested')
  })

  it('should restrict from passing the result to unauthorized', async () => {
    await expectRevert.unspecified(
      this.oracleId._callback(this.queryId, '987654321', { from: thirdparty })
    )
  })

  it('should allow to pass result', async () => {
    const customResult = '12345678'

    await this.oracleId._callback(this.queryId, customResult, { from: owner })

    const hasData = await this.oracleAggregator.hasData.call(this.oracleId.address, this.now)
    const data = await this.oracleAggregator.getData.call(this.oracleId.address, this.now)

    assert.isTrue(hasData, 'Data was not provided')
    assert.equal(data.toString(), customResult.toString(), 'Data do not match')
  })
})
