const HDWalletProvider = require('@truffle/hdwallet-provider')
const mnemonicOther = ''
const mnemonicMainnet = ''

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      gasPrice: 5e9,
      networkId: '*',
    },

    rinkeby: {
      provider: new HDWalletProvider(mnemonicOther, 'https://rinkeby.infura.io/v3/'),
      network_id: 4,
      gas: 5000000,
      gasPrice: 5e9
    },

    mainnet: {
      provider: new HDWalletProvider(mnemonicMainnet, 'https://mainnet.infura.io/v3/'),
      network_id: 1,
      gas: 2e6,
      gasPrice: 35e9
    }
  },
}
