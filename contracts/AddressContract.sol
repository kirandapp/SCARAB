//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AddressContract is Ownable {

    address private Dao;
    address private Treasury;
    address private ScarabNFT;
    address private Scarab;

    function setContractAddresses(address _dao, address _treasury, address _scarabnft, address _scarab) external onlyOwner {
        Dao = _dao;
        Treasury = _treasury;
        ScarabNFT = _scarabnft;
        Scarab = _scarab;
    }

    function setDao(address _dao) external onlyOwner {
        Dao = _dao;
    }

    function setTreasury(address _treasury) external onlyOwner {
        Treasury = _treasury;
    }

    function setScarabNFT(address _scarabnft) external onlyOwner {
       ScarabNFT = _scarabnft;
    }

    function setScarab(address _scarab) external onlyOwner {
       Scarab = _scarab;
    }

    function getDao() external view returns (address) {
        return Dao;
    }

    function getTreasury() external view returns (address) {
        return Treasury;
    }

    function getScarabNFT() external view returns (address) {
        return ScarabNFT;
    }

    function getScarab() external view returns (address) {
        return Scarab;
    }
}