pragma solidity 0.5.16;

import "@chainlink/contracts/src/v0.5/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.5/interfaces/LinkTokenInterface.sol";

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "opium-contracts/contracts/Interface/IOracleId.sol";
import "opium-contracts/contracts/OracleAggregator.sol";

contract OlivePriceChainlinkOracleId is ChainlinkClient, IOracleId, Ownable {
  using SafeMath for uint256;

  event Requested(bytes32 indexed queryId, uint256 indexed timestamp);
  event Provided(bytes32 indexed queryId, uint256 indexed timestamp, uint256 result);

  mapping (bytes32 => uint256) public pendingQueries;

  // Opium
  OracleAggregator public oracleAggregator;

  // Chainlink
  address public oracle;
  bytes32 public jobId;
  uint256 public fee;

  // Governance
  uint256 public EMERGENCY_PERIOD;

  // Price data
  uint256 public price;
  

  constructor(OracleAggregator _oracleAggregator, uint256 _emergencyPeriod) public {
    oracleAggregator = _oracleAggregator;
    EMERGENCY_PERIOD = _emergencyPeriod;

    setPublicChainlinkToken();
    /**
    Rinkeby
     */
    oracle = 0x7AFe1118Ea78C1eae84ca8feE5C65Bc76CcF879e;
    jobId = "6d1bfe27e7034b1d87b5270556b17277";
    fee = 0.1 * 10 ** 18; // 0.1 LINK
    
    /**
     * Mainnet
     */
    /*
    oracle = 0x2ed7e9fcd3c0568dc6167f0b8aee06a02cd9ebd8;
    jobId = "a32d79b72f28437b8a30788ca62b0f21";
    fee = 0.1 * 10 ** 18; // 0.1 LINK
        
    */
    /*
    {
      "author": "OlivaCoin.Raul",
      "description": "OlivaFuturesPrice Oracle",
      "asset": "OliveOil",
      "type": "onchain",
      "source": "chainlink",
      "logic": "none",
      "path": "latestAnswer()"
    }
    */
    emit MetadataSet("{\"author\":\"OlivaCoin.Raul\",\"description\":\"OlivaFuturesPrice Oracle\",\"asset\":\"OliveOil\",\"type\":\"onchain\",\"source\":\"chainlink\",\"logic\":\"none\",\"path\":\"latestAnswer()\"}");
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

    oracleAggregator.__callback(timestamp, price);

    emit Provided(_queryId, timestamp, price);
  }

  /** CHAINLINK */
  /**
    @notice request latest oliva price 
   */  
   function requestPrice() public returns (bytes32 requestId) {

      Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
      // Set the URL to perform the GET request on
      request.add("get", "http://kohonen.pythonanywhere.com/");
        
      // Set the path to find the desired data in the API response, where the response format is:
      // {
      //   "price": xxx.xxx,
      // }

      request.add("path", "price");
        
        // Multiply the result by 1000000000000000000 to remove decimals
      int timesAmount = 10**18;
      request.addInt("times", timesAmount);
        
      // Sends the request
      return sendChainlinkRequestTo(oracle, request, fee);
  }
    
  /**
  * Receive the response in the form of uint256
  */ 
  function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId)
  {
    price = _price;
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

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }
}
