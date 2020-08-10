pragma solidity 0.5.16;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "opium-contracts/contracts/Interface/IOracleId.sol";
import "opium-contracts/contracts/OracleAggregator.sol";

contract RawOracleId is IOracleId, Ownable {
  using SafeMath for uint256;

  event Requested(bytes32 indexed queryId, uint256 indexed timestamp);
  event Provided(bytes32 indexed queryId, uint256 indexed timestamp, uint256 result);

  mapping (bytes32 => uint256) public pendingQueries;

  // Opium
  OracleAggregator public oracleAggregator;

  constructor(OracleAggregator _oracleAggregator) public {
    oracleAggregator = _oracleAggregator;
  }

  /** OPIUM */
  function fetchData(uint256 _timestamp) external payable {
    require(_timestamp > 0, "Timestamp must be nonzero");

    bytes32 queryId = keccak256(abi.encodePacked(address(this), _timestamp));
    pendingQueries[queryId] = _timestamp;
    emit Requested(queryId, _timestamp);
  }

  function recursivelyFetchData(uint256 _timestamp, uint256 _period, uint256 _times) external payable {
    require(_timestamp > 0, "Timestamp must be nonzero");

    for (uint256 i = 0; i < _times; i++) {
      uint256 moment = _timestamp + _period * i;
      bytes32 queryId = keccak256(abi.encodePacked(address(this), moment));
      pendingQueries[queryId] = moment;
      emit Requested(queryId, moment);
    }
  }

  function calculateFetchPrice() external returns (uint256) {
    return 0;
  }
  
  function _callback(bytes32 _queryId, uint256 _result) public onlyOwner {
    uint256 timestamp = pendingQueries[_queryId];
    require(
      !oracleAggregator.hasData(address(this), timestamp) &&
      timestamp < now,
      "Only when no data and after timestamp allowed"
    );

    oracleAggregator.__callback(timestamp, _result);

    emit Provided(_queryId, timestamp, _result);
  }
}
