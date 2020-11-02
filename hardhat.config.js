require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-waffle");

const secrets = require('./secrets.json');
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "rinkeby",
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/"+secrets.projectId,
      accounts: [secrets.privateKey]
    },
    kovan: {
      url: "https://kovan.infura.io/v3/"+secrets.projectId,
      accounts: [secrets.privateKey]
    }
  },
  solidity: {
    version:"0.5.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};