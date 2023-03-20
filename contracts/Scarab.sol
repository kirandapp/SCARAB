
// File: contracts/Scarab.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Scarab is ERC20, Ownable {
    uint256 public tax = 4;
    address public treasury = 0x000000000000000000000000000000000000dEaD; //where tax tokens will store

    constructor() ERC20("Scarab", "SCRB") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 value) public {
        _mint(to, value);
    }
    function setTreasuryAddress(address _treasury) external onlyOwner{
        require(_treasury != address(0), "setTreasuryAddress: Zero address");
        treasury = _treasury;
    }
    
    function setTax(uint256 _tax) external onlyOwner{
        tax = _tax;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override{  
            uint256 taxAmount = amount * tax / 100;
            super._transfer(sender,treasury,taxAmount);
            super._transfer(sender,recipient,amount-(taxAmount));
            // ITreasury(treasury).validatePayout();
    }
}