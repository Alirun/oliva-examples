pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

import "opium-contracts/contracts/Interface/IDerivativeLogic.sol";

contract FutureSyntheticId is IDerivativeLogic, Ownable {
  using SafeMath for uint256;

  address private author;
  uint256 private commission;

  uint256 public BASE_PPT;

  constructor() public {
    /*
    {
      "author": "Opium.Team",
      "type": "future",
      "subtype": null,
      "description": "Future logic contract"
    }
    */
    emit MetadataSet("{\"author\":\"Opium.Team\",\"type\":\"future\",\"subtype\":null,\"description\":\"Future logic contract\"}");
    
    author = msg.sender;
    commission = 25; // 0.25% of profit

    BASE_PPT = 1e18;
  }

  // params[0] - Future price
  // params[1] - PPT (Sensitivity)
  function validateInput(Derivative memory _derivative) public view returns (bool) {
    return (
      // Derivative
      _derivative.endTime > now &&
      _derivative.margin > 0 &&
      _derivative.params.length == 2 &&

      _derivative.params[0] > 0 && // Future price > 0
      _derivative.params[1] > 0 // PPT > 0
    );
  }

  function getMargin(Derivative memory _derivative) public view returns (uint256 buyerMargin, uint256 sellerMargin) {
    buyerMargin = _derivative.margin;
    sellerMargin = _derivative.margin;
  }

  function getExecutionPayout(Derivative memory _derivative, uint256 _result) public view returns (uint256 buyerPayout, uint256 sellerPayout) {
    uint256 profit;

    uint256 futurePrice = _derivative.params[0];
    uint256 ppt = _derivative.params[1];

    if (_result > futurePrice) {
      profit = _result.sub(futurePrice);
      profit = profit.mul(ppt).div(BASE_PPT);

      if (profit > _derivative.margin) {
        buyerPayout = uint256(2).mul(_derivative.margin);
        sellerPayout = 0;
      } else {
        buyerPayout = _derivative.margin.add(profit);
        sellerPayout = _derivative.margin.sub(profit);
      }
    } else {
      profit = futurePrice.sub(_result);
      profit = profit.mul(ppt).div(BASE_PPT);

      if (profit > _derivative.margin) {
        buyerPayout = 0;
        sellerPayout = uint256(2).mul(_derivative.margin);
      } else {
        buyerPayout = _derivative.margin.sub(profit);
        sellerPayout = _derivative.margin.add(profit);
      }
    }
  }

  /** COMMISSION */
  /// @notice Getter for syntheticId author address
  /// @return address syntheticId author address
  function getAuthorAddress() public view returns (address) {
    return author;
  }

  /// @notice Getter for syntheticId author commission
  /// @return uint26 syntheticId author commission
  function getAuthorCommission() public view returns (uint256) {
    return commission;
  }

  /** POOL */
  function isPool() public view returns (bool) {
    return false;
  }

  /** THIRDPARTY EXECUTION */
  function thirdpartyExecutionAllowed(address derivativeOwner) public view returns (bool) {
    derivativeOwner;
    return true;
  }

  function allowThirdpartyExecution(bool allow) public {
    allow;
  }

  /** GOVERNANCE */
  function setAuthorAddress(address _author) public onlyOwner {
    require(_author != address(0), "Can't set to zero address");
    author = _author;
  }

  function setAuthorCommission(uint256 _commission) public onlyOwner {
    commission = _commission;
  }
}
