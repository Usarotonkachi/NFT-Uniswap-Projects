// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import Uniswap V2 interfaces
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

//import "./Ownable.sol";

contract newTask {
    IUniswapV2Router02 private uniswapRouter;
    address private factoryAddress;

    constructor(address _uniswapRouter, address _factoryAddress) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        factoryAddress = _factoryAddress;
    }

    function getMinAmountOut(
        address[] memory path,
        uint256 amountIn
    ) public view returns (uint256) {
        uint256[] memory amountsOut = uniswapRouter.getAmountsOut(
            amountIn,
            path
        );
        return amountsOut[amountsOut.length - 1];
    }

    function swapETHtoToken(
        uint amountOutMin,
        address tokenAdr
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(uniswapRouter).WETH();
        path[1] = tokenAdr;
        uniswapRouter.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapTokentoETH(
        uint amountIn,
        uint amountOutMin,
        address tokenAdr
    ) external {
        address[] memory path = new address[](2);
        path[0] = tokenAdr;
        path[1] = IUniswapV2Router02(uniswapRouter).WETH();

        IERC20(tokenAdr).approve(address(uniswapRouter), amountIn);

        uniswapRouter.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    /*function executeArbitrage(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 deadline
    ) external {
        // Get the pair address from the Uniswap factory
        IUniswapV2Pair pair = IUniswapV2Pair(
            IUniswapV2Factory(factoryAddress).getPair(tokenA, tokenB)
        );

        // Ensure the pair exists
        require(address(pair) != address(0), "Pair does not exist");

        // Approve the router to spend the tokens
        IERC20(tokenA).approve(address(uniswapRouter), amountA);
        IERC20(tokenB).approve(address(uniswapRouter), amountB);

        // Perform the arbitrage trade
        uniswapRouter.swapExactTokensForTokens(
            amountA,
            amountB,
            getPathForTokens(tokenA, tokenB),
            address(this),
            deadline
        );
    }*/

    function getPathForTokens(
        address tokenA,
        address tokenB
    ) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        return path;
    }

    fallback() external payable {}

    receive() external payable {}
}
