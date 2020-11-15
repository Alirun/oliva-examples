# Installation

Run `npm i`

# Test

1) Rename `test-environment.config.example.js` -> `test-environment.config.js`
2) Change `${infuraId}` in `test-environment.config.js`
3) Run `npm run test`

# Request price

Folder scripts contains several Hardhat scripts to operate the oracle


1) Create a file named secrets.json

```
{

  "mnemonic": ... 12 words deployer address,
  "projectId": infura project id,
  "privateKey": pk deployer address
}
```
Deployer account must have (Rinkeby Ether)[https://faucet.rinkeby.io/] and (testnet Link)[https://rinkeby.chain.link/]



2) To deploy and request initial price run 
```npx hardhat --network rinkeby run scripts/deployAndRequestPrice.js```

4) To  request prices,  
```
set the address of your oracle in the variable deployedOracleAddress in scripts/requestPrice.js

then run 

npx hardhat --network rinkeby run scripts/requestPrice.js 

```

5) To check all prices in the oraclr 
```
set the address of your oracle in the variable deployedOracleAddress in scripts/checkPrices.js

then run 

npx hardhat --network rinkeby run scripts/checkPrices.js 

```