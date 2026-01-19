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

    /*//////////////////////////////////////////////////////////////
                           CONSTANT VARIABLES
    //////////////////////////////////////////////////////////////*/
    // Used to scale Chainlink ETH price (price feed decimals adjustment)
    uint256 private constant PRECISION = 1e10;

    // Used to normalize ETH amount to 18 decimals
    uint256 private constant PRICE_PRECISION = 1e18;

    uint256 private constant buy_fee = 10;
    uint256 private constant fee_pricision =100;
    uint256 private constant sell_fee = 15;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() ERC20("FortuneFlip", "Flip") Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    // Ensures msg.sender is valid and ETH sent is non-zero
    modifier ethAmountAndAddressChecks() {
        if (msg.sender == address(0)) {
            revert StableToken__UserBuyingAddressCantBeZero();
        }

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

        uint256 _amountWorth = _getAndConvertEthPrice(msg.value);
      uint256 amountMinintfeeRemoved = (_amountWorth * buy_fee)/fee_pricision;
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
        uint256 ethWorth = _convertUSDToEth(amount);

        uint256 fee = (ethWorth * sell_fee)/fee_pricision;
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
    function _getAndConvertEthPrice(uint256 ethAmount) internal view returns (uint256 _amountWorth) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        (, int256 price,,,) = priceFeed.latestRoundData();

        // Token amount = ETH price * ETH sent, scaled
        _amountWorth = ((uint256(price) * PRECISION) * ethAmount) / PRICE_PRECISION;
    }

    // Converts token amount back to ETH based on Chainlink price feed
    function _convertUSDToEth(uint256 _amountWorth) internal view returns (uint256 ethAmount) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);

        (, int256 price,,,) = priceFeed.latestRoundData();

        // ETH amount = token USD value divided by ETH price
        ethAmount = (_amountWorth * PRICE_PRECISION) / (uint256(price) * PRECISION);
    }
}
