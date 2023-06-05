//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IAddressContract.sol";
import "./interfaces/IDao.sol";
import "./interfaces/ITreasury.sol";

contract ScarabNft is ERC721, ERC721Enumerable, Ownable, IERC721Receiver {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    IERC20 public tokenContract;
    uint256 public nftConversionRate = 100000000 ether;
    uint256 public maxGuardianSupport = 50;
    uint256 private nftid;
    uint256 public collectedFee;
    address public dao;
    address public treasury;


    mapping(uint => uint) public tokenLocked;

    event TokensConvertedToNFT(address from, uint256 tokenAmount, uint256 NftId);
    event NFTRedeemedForTokens(address from, uint256 tokenAmount, uint256 NftId);

    constructor() ERC721("ScarabNft","SCRBNFT") {
    }

    function setContractFactory(IAddressContract _contractFactory) external onlyOwner {
        tokenContract =  IERC20(_contractFactory.getScarab());
        dao = _contractFactory.getDao();
        treasury = _contractFactory.getTreasury();
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current() + 1;
        require(tokenId <= maxGuardianSupport, "Max Mint reached!");
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function batchMint(address to, uint256 numberOfNftIds) external {
        for (uint i = 0; i < numberOfNftIds; i++) {
            safeMint(to);
        }
    }

    function lockTokensAndMintNft() public  {
        uint _rate = nftConversionRate;
        require(balanceOf(msg.sender) == 0, "already a guardian");
        require(tokenContract.balanceOf(msg.sender) >= _rate,"Insufficient Balance");
        require(balanceOf(address(this)) > 0 , "no id available");
        uint nftId = tokenOfOwnerByIndex(address(this),0);
        tokenLocked[nftId] = _rate;
        _transfer(address(this), msg.sender, nftId);
        tokenContract.transferFrom(msg.sender, address(this), _rate);
        emit TokensConvertedToNFT(msg.sender, _rate, nftId);
    }

    function unlockTokens(uint256 _nftId) public  {

        require(_exists(_nftId), "NFT does not exist");
        require(msg.sender == ownerOf(_nftId), "Only the owner can redeem the NFT");
        
        uint _acitvePid = IDao(dao).getActiveProposal(_nftId);
        require(_acitvePid == 0, "There is active proposal with this Id");

        uint _blackListPid = IDao(dao).getBlackistedProposal(_nftId);

        uint unlockAmount;
        if (_blackListPid == 0) {
            transferFrom(msg.sender, address(this), _nftId);
            unlockAmount = tokenLocked[_nftId];
        }
        // susptected guardian 
        else {
            uint proposalAmount = IDao(dao).getProposalAmount(_blackListPid);
            transferFrom(msg.sender, address(this), _nftId);
            uint _amnt =  ITreasury(treasury).getExpectedScrabToken(proposalAmount);
            unlockAmount = tokenLocked[_nftId];
            if (unlockAmount > _amnt) {
                unlockAmount -= _amnt;
                collectedFee += _amnt;
            }
            IDao(dao).unlockBlacklistGuardian(_nftId);
        }

        tokenLocked[_nftId] = 0;
        tokenContract.transfer(msg.sender, unlockAmount);

        emit NFTRedeemedForTokens(msg.sender, nftConversionRate, _nftId);
    }

    function changeConversionRate(uint _rate) external onlyOwner  {
        nftConversionRate = _rate;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}

     function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function sendFeestoTreasury() external onlyOwner  {
        if (collectedFee > 0) {
            tokenContract.transfer(treasury, collectedFee);
        }
    }
}