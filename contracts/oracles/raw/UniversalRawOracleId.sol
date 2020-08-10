pragma solidity 0.5.16;

import "./RawOracleId.sol";

contract UniversalRawOracleId is RawOracleId {
  constructor(OracleAggregator _oracleAggregator) public RawOracleId(_oracleAggregator) {
    /*
    {
      "author": "Opium.Team",
      "description": "Universal Oracle",
      "asset": "Universal",
      "type": "multisig",
      "source": "opiumteam",
      "logic": "none",
      "path": "none"
    }
    */
    emit MetadataSet("{\"author\":\"Opium.Team\",\"description\":\"Universal Oracle\",\"asset\":\"Universal\",\"type\":\"multisig\",\"source\":\"opiumteam\",\"logic\":\"none\",\"path\":\"none\"}");
  }
}
