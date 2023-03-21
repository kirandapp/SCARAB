// File: contracts/Treasury.sol
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/Uniswap.sol";
import "hardhat/console.sol";

contract Treasury is Ownable, ReentrancyGuard
{
    using SafeMath for uint256;
    // address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    IERC20 public scarab;
    IUniswapV2Router public router;
    address public weth;

    event SwapComplete(uint256 ethAmount);

   
    constructor(        
        address _scarab,
        address _router
        ) {
        require(_scarab != address(0),"Invalid address");
        require(_router != address(0),"Invalid address");
        scarab = IERC20(_scarab);
        router = IUniswapV2Router(_router);
        weth = IUniswapV2Router(_router).WETH();

        scarab.approve(address(router), 2**256 - 1);
        // totalETH = 1 ether;
    }

    receive() external payable {}

    function executeSwap() public nonReentrant{
        console.log("13");
        address[] memory path = new address[](2);
        path[0] = address(scarab);
        path[1] = weth;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            scarab.balanceOf(address(this)),
            10,
            path,
            address(this),
            block.timestamp + 300
        );
        console.log("14");
        emit SwapComplete(address(this).balance);
        console.log("15");
    }     

    function fundTransfer(address _proposeeAdd, uint256 ethAmount) external {
        executeSwap();
        console.log("3");
        uint ethBal = address(this).balance;
        require(ethBal >= ethAmount, "");
        console.log("4");
        (bool sent, ) = address(_proposeeAdd).call{value: ethAmount}("");
        console.log("5");
        require(sent, "Failed to send Ether");    
    }

}