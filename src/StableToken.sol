// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 *Note this code is not tightly pegged to eth yet will fixed that
 */

contract StableToken is ERC20, Ownable {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error StableToken__UserBuyingAddressCantBeZero();
    error StableToken__EthAmountCantBeZero();
    error StableToken__BalanceIsZero();
    error StableToken__InsufficientBalance();
    error StableToken__NoEnoughLiquidity();
    error StableToken__FailedToTransferEth();
    error StableToken__UserSellingAddressCantBeZero();
    error StableToken__FailedToWithdrawEthLiquidity();
  error StableToken__NoLiquidityToWithdraw();

    /*//////////////////////////////////////////////////////////////
                           CONSTANT VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Used to scale Chainlink ETH price (price feed decimals adjustment)
    uint256 private constant PRECISION = 1e10;

    // Used to normalize ETH amount to 18 decimals
    uint256 private constant PRICE_PRECISION = 1e18;

    uint256 private constant buy_fee = 10;
    uint256 private constant fee_pricision = 100;
    uint256 private constant sell_fee = 15;
    address private immutable feeAddress;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _feedaddress) ERC20("FortuneFlip", "Flip") Ownable(msg.sender) {
        feeAddress = _feedaddress;
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    // Ensures msg.sender is valid and ETH sent is non-zero
    modifier ethAmountAndAddressChecks() {
        if (msg.value == 0) {
            revert StableToken__EthAmountCantBeZero();
        }

        _;
    }

    // Ensures the user has enough token balance for sell
    modifier checkBalanceOfUser(uint256 _amount) {
        if (balanceOf(msg.sender) == 0) {
            revert StableToken__BalanceIsZero();
        }

        if (balanceOf(msg.sender) < _amount) {
            revert StableToken__InsufficientBalance();
        }

        _;
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Mints tokens to the specified user based on ETH sent
    function buyToken(address to) external payable ethAmountAndAddressChecks onlyOwner returns (bool) {
        if (to == address(0)) {
            revert StableToken__UserBuyingAddressCantBeZero();
        }

        uint256 _amountWorth = getAndConvertEthPrice(msg.value);
        uint256 amountMinintfeeRemoved = (_amountWorth * buy_fee) / fee_pricision;
        uint256 amount = _amountWorth - amountMinintfeeRemoved;

        // Mint tokens to the user
        super._mint(to, amount);

        return true;
    }

    /**
     * @dev Sell tokens back to the contract for ETH.
     * Caller must:
     * - own the tokens
     * - have approved this contract to spend them
     */
    function sellToken(address to, uint256 amount) external checkBalanceOfUser(amount) onlyOwner returns (bool) {
        if (to == address(0)) {
            revert StableToken__UserSellingAddressCantBeZero();
        }

        // Calculate the ETH amount to send for the given token amount
        uint256 ethWorth = convertUSDToEth(amount);

        uint256 fee = (ethWorth * sell_fee) / fee_pricision;
        uint256 ethWorthSellfeeRemoved = ethWorth - fee;

        // Check that the contract has enough ETH to pay
        if (address(this).balance < ethWorthSellfeeRemoved) {
            revert StableToken__NoEnoughLiquidity();
        }

        // Burn the tokens from the caller
        _burn(msg.sender, amount);

        // Send ETH to the user
        (bool success,) = payable(to).call{value: ethWorthSellfeeRemoved}("");
        if (!success) {
            revert StableToken__FailedToTransferEth();
        }

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Converts ETH amount to token amount using Chainlink ETH/USD price feed
    function getAndConvertEthPrice(uint256 ethAmount) public view returns (uint256 _amountWorth) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feeAddress);

        (, int256 price,,,) = priceFeed.latestRoundData();

        // Token amount = ETH price * ETH sent, scaled
        _amountWorth = ((uint256(price) * PRECISION) * ethAmount) / PRICE_PRECISION;
    }

    // Converts token amount back to ETH based on Chainlink price feed
    function convertUSDToEth(uint256 _amountWorth) public view returns (uint256 ethAmount) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feeAddress);

        (, int256 price,,,) = priceFeed.latestRoundData();

        // ETH amount = token USD value divided by ETH price
        ethAmount = (_amountWorth * PRICE_PRECISION) / (uint256(price) * PRECISION);
    }

    // for testing

    function removeLiquidity() external onlyOwner {
        address owner = owner();


        if (address(this).balance == 0) {
            revert StableToken__NoLiquidityToWithdraw();
        }


        (bool success,) = payable(owner).call{value: address(this).balance}("");

        if (!success) {
            revert StableToken__FailedToWithdrawEthLiquidity();
        }
    }

    function getPrecision() external pure returns (uint256) {
        return PRECISION;
    }

    function getPricePrecision() external pure returns (uint256) {
        return PRICE_PRECISION;
    }

    function getBuyFee() external pure returns (uint256) {
        return buy_fee;
    }

    function getSellFee() external pure returns (uint256) {
        return sell_fee;
    }

    function getFeePrecision() external pure returns (uint256) {
        return fee_pricision;
    }

    function getFeeAddress() external view returns (address) {
        return feeAddress;
    }
}
