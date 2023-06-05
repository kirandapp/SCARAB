// File: contracts/Treasury.sol
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAddressContract.sol";
import "./interfaces/IUniswap.sol";

interface ScarabToken is IERC20 {
    function burn(uint amount) external;
}

contract Treasury is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    ScarabToken public scarab;
    IUniswapV2Router public router =
        IUniswapV2Router(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    address public weth;

    uint public guardianProfit = 1000; //  10%
    uint public buyBackandBurn = 5000; //  50%
    uint public communityProfit = 4000; //  40%

    uint public pendingProfitGuardian;
    uint public pendingProfitCommunity;
    uint public totalBuyBackAndBurn;

    address public dao;
    address public treasury;

    event SwapComplete(uint256 ethAmount);


    receive() external payable {}

    modifier onlyDao() {
        require(msg.sender == dao, "caller not dao");
        _;
    }

    function setContractFactory(IAddressContract _contractFactory) external onlyOwner {
        scarab =  ScarabToken(_contractFactory.getScarab());
        weth = router.WETH();
        scarab.approve(address(router), 2 ** 256 - 1);
        dao = _contractFactory.getDao();
        treasury = _contractFactory.getTreasury();
    }

    function swapTokensforEth(uint _amount) internal  {
        address[] memory path = new address[](2);
        path[0] = address(scarab);
        path[1] = weth;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
           _amount,
            10,
            path,
            address(this),
            block.timestamp + 300
        );
        emit SwapComplete(address(this).balance);
    }

    function swapEthforTokens(uint _amount) internal  {
        address[] memory path = new address[](2);
        path[1] = address(scarab);
        path[0] = weth;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
            0,
            path,
            address(this),
            block.timestamp + 300
        );
        emit SwapComplete(address(this).balance);
    }

    function fundTransfer(address _proposeeAdd, uint256 ethAmount) external {
       
       uint buffer = ethAmount * 2 / 100;
       uint _conversionAmount = getExpectedScrabToken(ethAmount + buffer);
        
        if (_conversionAmount < scarab.balanceOf(address(this))) {
            swapTokensforEth(_conversionAmount);
        
            uint ethBal = address(this).balance;
            require(ethBal >= ethAmount, "not enough balance");
            (bool sent, ) = address(_proposeeAdd).call{value: ethAmount}("");
            require(sent, "Failed to send Ether");
            uint remainingEth = ethBal - ethAmount;
            if (remainingEth > 0 ) {
                swapEthforTokens(remainingEth);
                }
        }
        else {
            revert("treasury failed");
        }
    }

    function distributeProfit(
        uint256 _lendingAmount,
        uint256 _refundAmount
    ) external payable onlyDao {
        
        uint profit = _refundAmount - _lendingAmount;
        if (profit > 0) {
            uint beforeSwapBal = scarab.balanceOf(address(this));
            swapEthforTokens(profit);
            uint afterSwapBal = scarab.balanceOf(address(this));
            uint tokenBal = afterSwapBal - beforeSwapBal;

            pendingProfitGuardian += (tokenBal * guardianProfit) / 10000;
            pendingProfitCommunity += (tokenBal * communityProfit) / 10000;
            uint burnBal = (tokenBal * buyBackandBurn) / 10000;
            totalBuyBackAndBurn += burnBal;

            scarab.burn(burnBal);
        }

        // swap remaining eth 
        swapEthforTokens(address(this).balance);
    }

    function getExpectedScrabToken(uint _amount) public view returns(uint) {
        address pairAddress =  IUniswapV2Factory(router.factory()).getPair(address(scarab), weth);
        address token0 = IUniswapV2Pair(pairAddress).token0();

        address[] memory _path = new address[](2);

        if (token0 == weth) {
            _path[0] = weth;
            _path[1] = address(scarab);
            uint[] memory amount = router.getAmountsOut(_amount, _path);
            return amount[1];
        }
        else {
            _path[0] = address(scarab);
            _path[1] = weth;
            uint[] memory amount = router.getAmountsIn(_amount, _path);
            return amount[0];
        }    
    }

    function injectFunds(uint _amount) external onlyOwner {
        scarab.transferFrom(msg.sender, address(this), _amount);
    }

    function removeFunds(address _admin,  uint _amount) external onlyOwner {
        scarab.transfer(_admin, _amount);
    }
}