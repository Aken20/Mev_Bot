// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract MEVArbitrageBot {
    address public owner;
    IUniswapV2Router public uniswapRouter;
    address public WETH;
    
    event ArbitrageExecuted(address token, uint profit, uint timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _router, address _WETH) {
        owner = msg.sender;
        uniswapRouter = IUniswapV2Router(_router);
        WETH = _WETH;
    }

    receive() external payable {}

    /// @dev Perform arbitrage between two tokens
    function executeArbitrage(
        address tokenA,
        address tokenB,
        uint amountIn
    ) external onlyOwner {
        uint initialETHBalance = address(this).balance;
        
        // Step 1: Buy TokenA with ETH
        uint tokenABought = swapETHForTokens(tokenA, amountIn);
        
        // Step 2: Swap TokenA to TokenB
        uint tokenBBought = swapTokens(tokenA, tokenB, tokenABought);
        
        // Step 3: Convert TokenB back to ETH
        uint finalETHBalance = swapTokensForETH(tokenB, tokenBBought);

        // Calculate profit
        uint profit = finalETHBalance - initialETHBalance;
        require(profit > 0, "No profit");

        emit ArbitrageExecuted(tokenB, profit, block.timestamp);
    }

    /// @dev Swaps ETH for a specific token
    function swapETHForTokens(address token, uint amountIn) private returns (uint) {
        address;
        path[0] = WETH;
        path[1] = token;

        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{value: amountIn}(
            0,
            path,
            address(this),
            block.timestamp + 120
        );
        return amounts[1];
    }

    /// @dev Swaps one ERC20 token for another
    function swapTokens(address tokenIn, address tokenOut, uint amountIn) private returns (uint) {
        IERC20(tokenIn).approve(address(uniswapRouter), amountIn);
        
        address;
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp + 120
        );
        return amounts[1];
    }

    /// @dev Swaps a specific token for ETH
    function swapTokensForETH(address token, uint amountIn) private returns (uint) {
        IERC20(token).approve(address(uniswapRouter), amountIn);
        
        address;
        path[0] = token;
        path[1] = WETH;

        uint[] memory amounts = uniswapRouter.swapExactTokensForETH(
            amountIn,
            0,
            path,
            address(this),
            block.timestamp + 120
        );
        return amounts[1];
    }

    /// @dev Withdraws all ETH from the contract
    function withdrawETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /// @dev Withdraws any ERC20 token from the contract
    function withdrawToken(address token) external onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");
        IERC20(token).transfer(owner, balance);
    }

    /// @dev Destroys the contract and sends remaining funds to owner
    function killContract() external onlyOwner {
        selfdestruct(payable(owner));
    }
}
