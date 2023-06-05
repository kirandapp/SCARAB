
// File: contracts/Scarab.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressContract.sol";

contract Scarab is ERC20, Ownable {
    uint256 public tax = 4;
    address public treasury = 0x000000000000000000000000000000000000dEaD; //where tax tokens will store
    mapping(address => bool) public whitelistedAddress;

    event TreasuryAddressUpdated(address newTreasury);
    event WhitelistAddressUpdated(address whitelistAccount, bool value);
    event TaxUpdated(uint256 taxAmount);

    constructor() ERC20("ScarabTest1", "SCRBT1") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 value) public {
        _mint(to, value);
    }
    
    function burn(uint amount) external {
        require(msg.sender == treasury, "only treasury can burn");
        _burn(msg.sender, amount);
    }

    function setContractFactory(IAddressContract _contractFactory) external onlyOwner {
        treasury = _contractFactory.getTreasury();
    }

    
    function setTax(uint256 _tax) external onlyOwner {
        tax = _tax;
        emit TaxUpdated(_tax);
    }

    function setWhitelistAddress(address _whitelist, bool _status) external onlyOwner {
        require(_whitelist != address(0), "setWhitelistAddress: Zero address");
        whitelistedAddress[_whitelist] = _status;
        emit WhitelistAddressUpdated(_whitelist, _status);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {  
        if(whitelistedAddress[sender] || whitelistedAddress[recipient]){
            super._transfer(sender,recipient,amount);
        } else{ 
            uint256 taxAmount = amount * tax / 100;
            super._transfer(sender,treasury,taxAmount);
            super._transfer(sender,recipient,amount-(taxAmount));
        }
    }
}
