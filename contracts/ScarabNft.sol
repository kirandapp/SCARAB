//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ScarabNft is ERC721 {
    IERC20 public tokenContract;
    uint256 public nftConversionRate = 100;
    uint256 private _totalSupply;

    event TokensConvertedToNFT(address from, uint256 tokenAmount, uint256 NftId);
    event NFTRedeemedForTokens(address from, uint256 tokenAmount, uint256 NftId);

    constructor(address _tokenContract) ERC721("ScarabNft","SCRBNFT") {
        tokenContract = IERC20(_tokenContract);
    }

    function convertTokenToNft(uint256 _amount) public {
        require(tokenContract.balanceOf(msg.sender) >= _amount,"Insufficient Balance");
        require(_amount >= nftConversionRate,"Insufficient tokens to convert to Nft");
        uint256 nftId = _totalSupply + 1;
        tokenContract.transferFrom(msg.sender, address(this), nftConversionRate);
        _safeMint(msg.sender, nftId);
        _totalSupply += 1;
        emit TokensConvertedToNFT(msg.sender, _amount, nftId);
    }

    function redeemNft(uint256 _nftId) public {
        require(_exists(_nftId), "NFT does not exist");
        // address owner = ownerOf(_nftId);
        require(msg.sender == ownerOf(_nftId), "Only the owner can redeem the NFT");
        tokenContract.transfer(msg.sender, nftConversionRate);
        _burn(_nftId);
        emit NFTRedeemedForTokens(msg.sender, nftConversionRate, _nftId);
    }
}