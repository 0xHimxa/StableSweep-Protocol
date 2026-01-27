// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title FortuneFlip Stable Token
 * @author Himxa
 * @notice ERC20 token with buy/sell mechanics pegged to ETH value via Chainlink price feeds.
 * @dev Takes a fee on buy (10%) and sell (15%) operations.
 *      Precision handling: Uses 1e10 to scale Chainlink's 8 decimals to 18 decimals.
 */
contract StableToken is ERC20, Ownable {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Thrown when buying address is zero address
    error StableToken__UserBuyingAddressCantBeZero();
    /// @notice Thrown when ETH amount sent for purchase is zero
    error StableToken__EthAmountCantBeZero();
    /// @notice Thrown when user balance is zero during sell check
    error StableToken__BalanceIsZero();
    /// @notice Thrown when user tries to sell more than they own
    error StableToken__InsufficientBalance();
    /// @notice Thrown when contract doesn't have enough ETH for sell redemption
    error StableToken__NoEnoughLiquidity();
    /// @notice Thrown when ETH transfer to seller fails
    error StableToken__FailedToTransferEth();
    /// @notice Thrown when selling address is zero address
    error StableToken__UserSellingAddressCantBeZero();
    /// @notice Thrown when owner fails to withdraw liquidity
    error StableToken__FailedToWithdrawEthLiquidity();
    /// @notice Thrown when trying to withdraw from empty contract
    error StableToken__NoLiquidityToWithdraw();

    /*//////////////////////////////////////////////////////////////
                           CONSTANT VARIABLES
    //////////////////////////////////////////////////////////////*/
    /// @dev Used to scale Chainlink ETH price (price feed decimals adjustment)
    /// @notice Chainlink price feeds usually have 8 decimals for ETH/USD.
    ///         To match Solidity's standard 18 decimals, we need to multiply by 1e10.
    ///         Example: Price $3000 -> 3000 * 10^8 (Chainlink) * 10^10 (Precision) = 3000 * 10^18.
    uint256 private constant PRECISION = 1e10;

    /// @dev Used to normalize ETH amount to 18 decimals
    uint256 private constant PRICE_PRECISION = 1e18;

    uint256 private constant buy_fee = 10;
    uint256 private constant fee_pricision = 100;
    uint256 private constant sell_fee = 15;
    address private immutable feeAddress;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Initializes the token and price feed
     * @param _feedaddress Address of the Chainlink V3 Aggregator (ETH/USD)
     */
    constructor(
        address _feedaddress
    ) ERC20("FortuneFlip", "Flip") Ownable(msg.sender) {
        feeAddress = _feedaddress;
    }

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Ensures msg.sender is valid and ETH sent is non-zero
    modifier ethAmountAndAddressChecks() {
        if (msg.value == 0) {
            revert StableToken__EthAmountCantBeZero();
        }

        _;
    }

    /// @dev Ensures the user has enough token balance for sell
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

    /**
     * @notice Mints tokens to the user in exchange for ETH.
     * @dev Applies a 10% buy fee.
     *
     * Example Scenario:
     * 1. User sends 1 ETH (assuming 1 ETH = $3000).
     * 2. Total Value = $3000.
     * 3. Fee (10%) = $300.
     * 4. User receives = $2700 worth of tokens.
     *
     * @param to The address to mint tokens to.
     * @return bool Success status.
     */
    function buyToken(
        address to
    ) external payable ethAmountAndAddressChecks onlyOwner returns (bool) {
        if (to == address(0)) {
            revert StableToken__UserBuyingAddressCantBeZero();
        }

        uint256 _amountWorth = getAndConvertEthPrice(msg.value);
        uint256 amountMinintfeeRemoved = (_amountWorth * buy_fee) /
            fee_pricision;
        uint256 amount = _amountWorth - amountMinintfeeRemoved;

        // Mint tokens to the user
        super._mint(to, amount);

        return true;
    }

    /**
     * @notice Sells tokens back to the contract for ETH.
     * @dev Applies a 15% sell fee. Caller must have approved contract or be owner.
     *
     * Example Scenario:
     * 1. User sells 100 Tokens (assuming 1 Token = $1).
     * 2. Total Value = $100.
     * 3. Equivalent ETH is calculated (e.g., 0.033 ETH if ETH=$3000).
     * 4. Fee (15%) is deducted from the ETH amount.
     * 5. User receives 85% of the ETH value.
     *
     * @param to The address to receive ETH.
     * @param amount The amount of tokens to sell.
     * @return bool Success status.
     */
    function sellToken(
        address to,
        uint256 amount
    ) external checkBalanceOfUser(amount) onlyOwner returns (bool) {
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
        (bool success, ) = payable(to).call{value: ethWorthSellfeeRemoved}("");
        if (!success) {
            revert StableToken__FailedToTransferEth();
        }

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Converts ETH amount to Token amount (USD value scaled).
     * @param ethAmount The amount of ETH to convert.
     * @return _amountWorth The equivalent Token amount.
     */
    function getAndConvertEthPrice(
        uint256 ethAmount
    ) public view returns (uint256 _amountWorth) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feeAddress);

        (, int256 price, , , ) = priceFeed.latestRoundData();

        // Token amount = ETH price * ETH sent, scaled
        _amountWorth =
            ((uint256(price) * PRECISION) * ethAmount) /
            PRICE_PRECISION;
    }

    /**
     * @notice Converts Token amount to ETH amount.
     * @param _amountWorth The amount of Tokens to convert.
     * @return ethAmount The equivalent ETH amount.
     */
    function convertUSDToEth(
        uint256 _amountWorth
    ) public view returns (uint256 ethAmount) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feeAddress);

        (, int256 price, , , ) = priceFeed.latestRoundData();

        // ETH amount = token USD value divided by ETH price
        ethAmount =
            (_amountWorth * PRICE_PRECISION) /
            (uint256(price) * PRECISION);
    }

    // for testing

    /**
     * @notice Withdraws all ETH liquidity from the contract.
     * @dev Only callable by owner. Used for testing or emergency drainage.
     */
    function removeLiquidity() external onlyOwner {
        address owner = owner();

        if (address(this).balance == 0) {
            revert StableToken__NoLiquidityToWithdraw();
        }

        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );

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
