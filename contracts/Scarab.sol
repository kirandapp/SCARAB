
// File: contracts/Scarab.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Scarab is ERC20, Ownable {
    uint256 public tax = 4;
    address public treasury = 0x000000000000000000000000000000000000dEaD; //where tax tokens will store
    mapping(address => bool) public whitelistedAddress;

    event TreasuryAddressUpdated(address newTreasury);
    event WhitelistAddressUpdated(address whitelistAccount, bool value);
    event TaxUpdated(uint256 taxAmount);

    constructor() ERC20("Scarab", "SCRB") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 value) public {
        _mint(to, value);
    }
    function setTreasuryAddress(address _treasury) external onlyOwner{
        require(_treasury != address(0), "setTreasuryAddress: Zero address");
        treasury = _treasury;
        whitelistedAddress[_treasury] = true;
        emit TreasuryAddressUpdated(_treasury);
    }
    
    function setTax(uint256 _tax) external onlyOwner{
        tax = _tax;
        emit TaxUpdated(_tax);
    }

    function setWhitelistAddress(address _whitelist, bool _status) external onlyOwner{
        require(_whitelist != address(0), "setWhitelistAddress: Zero address");
        whitelistedAddress[_whitelist] = _status;
        emit WhitelistAddressUpdated(_whitelist, _status);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override{  
        if(whitelistedAddress[sender] || whitelistedAddress[recipient]){
            super._transfer(sender,recipient,amount);
        } else{ 
            uint256 taxAmount = amount * tax / 100;
            super._transfer(sender,treasury,taxAmount);
            super._transfer(sender,recipient,amount-(taxAmount));
        }
    }
}