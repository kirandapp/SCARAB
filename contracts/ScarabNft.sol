//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract ScarabNft is ERC721, Ownable {
    IERC20 public tokenContract;
    uint256 public nftConversionRate = 100;
    uint256 private _totalSupply;
    uint256 public maxGuardianSupport = 50;
    address public daoContractAddress;
    mapping(uint256 => bool) public isGuardian;

    event TokensConvertedToNFT(address from, uint256 tokenAmount, uint256 NftId);
    event NFTRedeemedForTokens(address from, uint256 tokenAmount, uint256 NftId);

    constructor(address _tokenContract) ERC721("ScarabNft","SCRBNFT") {
        tokenContract = IERC20(_tokenContract);
    }

    function setDaoContractAddress(address _daoContract) public onlyOwner {
        // require(isContract(_daoContract), "address must be a contract");
        require(_daoContract.code.length > 0,"Address must be a Contract");
        daoContractAddress = _daoContract;
    }

    function lockTokensAndMintNft(uint256 _amount) public {
        require(!isGuardian[balanceOf(msg.sender)],"nftId already minted!!");
        require(_totalSupply <= maxGuardianSupport, "max guardian support reached.");
        require(tokenContract.balanceOf(msg.sender) >= _amount,"Insufficient Balance");
        require(_amount >= nftConversionRate,"Insufficient tokens to convert to Nft");
        uint256 nftId = _totalSupply + 1;
        tokenContract.transferFrom(msg.sender, address(this), nftConversionRate);
        _safeMint(msg.sender, nftId);
        _totalSupply += 1;
        isGuardian[nftId] = true;
        emit TokensConvertedToNFT(msg.sender, _amount, nftId);
    }

    function unlockTokens(uint256 _nftId) public {
        //TODO check the nftId holder doesn't have any active proposal
        //TODO if guardian suspected, can't unlock
        console.log("18");
        require(_exists(_nftId), "NFT does not exist");
        console.log("19");
        require(msg.sender == ownerOf(_nftId), "Only the owner can redeem the NFT");
        console.log("20");
        tokenContract.transfer(msg.sender, nftConversionRate);
        console.log("21");
        _burn(_nftId);
        console.log("22");
        emit NFTRedeemedForTokens(msg.sender, nftConversionRate, _nftId);
    }
}