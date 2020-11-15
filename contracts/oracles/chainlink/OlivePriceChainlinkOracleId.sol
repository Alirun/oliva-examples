pragma solidity 0.5.16;

import "@chainlink/contracts/src/v0.5/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.5/interfaces/LinkTokenInterface.sol";

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "opium-contracts/contracts/Interface/IOracleId.sol";
import "opium-contracts/contracts/OracleAggregator.sol";

contract OlivePriceChainlinkOracleId is ChainlinkClient, IOracleId, Ownable {
  using SafeMath for uint256;

  event Requested(uint256 indexed timestamp);
  event Provided(uint256 indexed timestamp, uint256 result);

  mapping (bytes32 => uint256) public pendingRequests;

  // Opium
  OracleAggregator public oracleAggregator;

  // Chainlink
  address public oracle;
  bytes32 public jobId;
  uint256 public fee;

  // Governance
  uint256 public EMERGENCY_PERIOD;

  constructor(OracleAggregator _oracleAggregator, uint256 _emergencyPeriod) public {
    oracleAggregator = _oracleAggregator;
    EMERGENCY_PERIOD = _emergencyPeriod;

    setPublicChainlinkToken();
    /**
    Rinkeby
     */
    setChainlinkNodeData(
      0x7AFe1118Ea78C1eae84ca8feE5C65Bc76CcF879e,
      "6d1bfe27e7034b1d87b5270556b17277",
      0.1 * 10 ** 18 // 0.1 LINK
    );
    
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
    _timestamp;
    revert("N.S"); // N.S = not supported
  }

  function recursivelyFetchData(uint256 _timestamp, uint256 _period, uint256 _times) external payable {
    _timestamp;
    _period;
    _times;
    revert("N.S"); // N.S = not supported
  }

  function calculateFetchPrice() external returns (uint256) {
    return 0;
  }
  
  function _fulfill(bytes32 _requestId, uint256 _price) private {
    uint256 timestamp = pendingRequests[_requestId];

    oracleAggregator.__callback(timestamp, _price);

    emit Provided(timestamp, _price);
  }

  /** CHAINLINK */
  /**
    @notice request latest oliva price 
   */  
   function requestPrice(uint256 _timestamp) public onlyOwner returns (bytes32 requestId) {
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
      requestId = sendChainlinkRequestTo(oracle, request, fee);

      pendingRequests[requestId] = _timestamp;

      emit Requested(_timestamp);
  }

  function setChainlinkNodeData(address _oracle, bytes32 _jobId, uint256 _fee) public onlyOwner {
    oracle = _oracle;
    jobId = _jobId;
    fee = _fee;
  }
    
  /**
  * Receive the response in the form of uint256
  */ 
  function fulfill(bytes32 _requestId, uint256 _price) public recordChainlinkFulfillment(_requestId)
  {
    _fulfill(_requestId, _price);
  }

  /** GOVERNANCE */
  /** 
    Emergency callback allows to push data manually in case EMERGENCY_PERIOD elapsed and no data were provided
   */
  function emergencyCallback(uint256 _timestamp, uint256 _result) public onlyOwner {
    require(
      !oracleAggregator.hasData(address(this), _timestamp) &&
      _timestamp + EMERGENCY_PERIOD  < now,
      "N.E" // N.E = Only when no data and after emergency period allowed
    );

    oracleAggregator.__callback(_timestamp, _result);

    emit Provided(_timestamp, _result);
  }

  function setEmergencyPeriod(uint256 _emergencyPeriod) public onlyOwner {
    EMERGENCY_PERIOD = _emergencyPeriod;
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
    
    require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
  }
}
