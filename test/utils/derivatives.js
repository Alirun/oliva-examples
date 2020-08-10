const { web3 } = require('@openzeppelin/test-environment')
const { constants } = require('@openzeppelin/test-helpers')

module.exports.derivativeFactory = (derivative) => {
  const def = {
    margin: 0,
    endTime: 0,
    params: [],
    oracleId: constants.ZERO_ADDRESS,
    token: constants.ZERO_ADDRESS,
    syntheticId: constants.ZERO_ADDRESS
  }

  return {
    ...def,
    ...derivative
  }
}

module.exports.getDerivativeHash = (derivative) => {
  return web3.utils.soliditySha3(
    derivative.margin,
    derivative.endTime,
    {
      type: 'uint256[]',
      value: derivative.params
    },
    derivative.oracleId,
    derivative.token,
    derivative.syntheticId,
  )
}
