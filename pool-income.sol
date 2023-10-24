pragma solidity ^0.8.0;

// Import ERC20 token interface
import "./IERC20.sol";

contract DecentralizedExchange {
    address public owner;

    struct LiquidityProvider {
        address provider;
        uint256 liquidityAmount;
        uint256 share;
    }

    IERC20 public token; // The token being traded
    uint256 public totalLiquidity;
    uint256 public totalShares;
    uint256 public tradingFeePercentage = 5; // 5% trading fee

    LiquidityProvider[] public liquidityProviders;

    // Mapping to track user balances
    mapping(address => uint256) public userBalances;

    event LiquidityAdded(address indexed provider, uint256 liquidityAmount);
    event Trade(address indexed buyer, address indexed seller, uint256 amount);

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    // Function for users to add liquidity to the pool
    function addLiquidity(uint256 _liquidityAmount) public {
        require(_liquidityAmount > 0, "Liquidity amount must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), _liquidityAmount), "Token transfer failed");

        // Calculate the user's share of the liquidity pool
        uint256 userShare = 0;
        if (totalLiquidity > 0) {
            userShare = (totalShares * _liquidityAmount) / totalLiquidity;
        }

        // Update the user's balance and total liquidity
        userBalances[msg.sender] += _liquidityAmount;
        totalLiquidity += _liquidityAmount;

        // Update the user's share and total shares
        liquidityProviders.push(LiquidityProvider(msg.sender, _liquidityAmount, userShare));
        totalShares += userShare;

        emit LiquidityAdded(msg.sender, _liquidityAmount);
    }

    // Function for users to trade tokens
    function trade(uint256 _amount) public {
        require(_amount > 0, "Trade amount must be greater than zero");
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");

        // Calculate the trading fee
        uint256 tradingFee = (_amount * tradingFeePercentage) / 100;
        uint256 amountAfterFee = _amount - tradingFee;

        // Transfer tokens from the sender to the DEX for the trade
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        // Distribute the trading fee to liquidity providers
        distributeTradingFee(tradingFee);

        // Perform the trade logic here (e.g., token exchange)

        // Update user balances
        userBalances[msg.sender] -= _amount;

        emit Trade(msg.sender, address(this), amountAfterFee);
    }

    // Function to distribute trading fees to liquidity providers
    function distributeTradingFee(uint256 _tradingFee) internal {
        for (uint256 i = 0; i < liquidityProviders.length; i++) {
            LiquidityProvider storage provider = liquidityProviders[i];
            uint256 feeShare = (provider.share * _tradingFee) / totalShares;
            userBalances[provider.provider] += feeShare;
        }
    }
}
