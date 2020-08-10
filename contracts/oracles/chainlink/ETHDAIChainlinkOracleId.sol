pragma solidity 0.5.16;

import "@chainlink/contracts/src/v0.5/dev/AggregatorInterface.sol";

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "opium-contracts/contracts/Interface/IOracleId.sol";
import "opium-contracts/contracts/OracleAggregator.sol";

contract ETHDAIChainlinkOracleId is IOracleId, Ownable {
  using SafeMath for uint256;

  event Requested(bytes32 indexed queryId, uint256 indexed timestamp);
  event Provided(bytes32 indexed queryId, uint256 indexed timestamp, uint256 result);

  mapping (bytes32 => uint256) public pendingQueries;

  // Opium
  OracleAggregator public oracleAggregator;

  // Chainlink
  AggregatorInterface internal ref;
  uint256 public CHAINLINK_ETH_BASE;
  uint256 public DAI_DECIMALS;

  // Governance
  uint256 public EMERGENCY_PERIOD;

  constructor(AggregatorInterface _chainlinkAggregator, OracleAggregator _oracleAggregator, uint256 _emergencyPeriod) public {
    ref = _chainlinkAggregator;
    oracleAggregator = _oracleAggregator;

    CHAINLINK_ETH_BASE = 1e18;
    DAI_DECIMALS = 1e18;

    EMERGENCY_PERIOD = _emergencyPeriod;
    /*
    {
      "author": "Opium.Team",
      "description": "ETH/DAI Oracle",
      "asset": "ETH/DAI",
      "type": "onchain",
      "source": "chainlink",
      "logic": "none",
      "path": "latestAnswer()"
    }
    */
    emit MetadataSet("{\"author\":\"Opium.Team\",\"description\":\"ETH/DAI Oracle\",\"asset\":\"ETH/DAI\",\"type\":\"onchain\",\"source\":\"chainlink\",\"logic\":\"none\",\"path\":\"latestAnswer()\"}");
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
  
  function _callback(bytes32 _queryId) public {
    uint256 timestamp = pendingQueries[_queryId];
    require(
      !oracleAggregator.hasData(address(this), timestamp) &&
      timestamp < now,
      "Only when no data and after timestamp allowed"
    );

    uint256 result = getReversedLatestPrice();
    oracleAggregator.__callback(timestamp, result);

    emit Provided(_queryId, timestamp, result);
  }

  /** CHAINLINK */
  /**
    @notice Returns DAI/ETH Price
   */
  function getLatestPrice() public view returns (int256) {
    return ref.latestAnswer();
  }

  /**
    @notice Returns ETH/DAI Price
   */
  function getReversedLatestPrice() public view returns (uint256) {
    uint256 price = uint256(getLatestPrice());
    return CHAINLINK_ETH_BASE.mul(DAI_DECIMALS).div(price);
  }

  /** GOVERNANCE */
  /** 
    Emergency callback allows to push data manually in case EMERGENCY_PERIOD elapsed and no data were provided
   */
  function emergencyCallback(bytes32 _queryId, uint256 _result) public onlyOwner {
    uint256 timestamp = pendingQueries[_queryId];
    require(
      !oracleAggregator.hasData(address(this), timestamp) &&
      timestamp + EMERGENCY_PERIOD  < now,
      "Only when no data and after emergency period allowed"
    );

    oracleAggregator.__callback(timestamp, _result);

    emit Provided(_queryId, timestamp, _result);
  }

  function setEmergencyPeriod(uint256 _emergencyPeriod) public onlyOwner {
    EMERGENCY_PERIOD = _emergencyPeriod;
  }
}
