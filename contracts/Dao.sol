// File: contracts/Dao.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Treasury.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Dao is Ownable{
    IERC20 public token;
    IERC721 public nft;
    address payable public treasury;

    uint256 public proposalCounter = 0;
    uint256 public maxProposalValue = 2000000000000000000; //2eth //20000000000000000000; // 20 ETH
    uint256 public votingTime = 120; // 2 minutes //86400; // 1 day in seconds

    event NewProposal(uint256 indexed id, string guardianName, address payable recipient, string projectName, string description, uint256 value, uint256 startTimestamp, uint256 endTimestamp);
    event Vote(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event ProposalExecuted(uint256 indexed proposalId);

    struct Proposal {
        uint256 id; //proposal counter is the id
        string guardianName;    //Name of the Guardian
        address payable recipient;  //Guardian Wallet address
        string projectName; //Name of the project
        string description; //project description
        uint256 value;  //fund value    
        bool executed;  //passed proposal
        uint256 votesFor;   //counter track for favor votes
        uint256 votesAgainst;   //counter track for against votes
        uint256 startTimestamp; //timestamp for when the proposal was created
        uint256 endTimestamp;   //timestamp for when the voting period of proposal end
        mapping(address => bool) voters;    //keep track of which guardian vote for proposal
    }
    mapping(uint256 => Proposal) public proposals;

    constructor(address _token, address _nft, address payable _treasury) {
        token = IERC20(_token);
        nft = IERC721(_nft);
        treasury = _treasury;
    }

    function createProposal(string memory guardianName, address payable recipient, string memory projectName, string memory description, uint256 value) public returns (uint256) {
        require(value <= maxProposalValue, "Proposal value too high");
        proposalCounter++;
        Proposal storage p = proposals[proposalCounter];
        p.id = proposalCounter;
        p.guardianName = guardianName;
        p.recipient = recipient;
        p.projectName = projectName;
        p.description = description;
        p.value = value;        
        p.executed = false;
        p.startTimestamp = block.timestamp;
        p.endTimestamp = block.timestamp + votingTime;
        emit NewProposal(proposalCounter, guardianName, recipient, projectName, description, value, p.startTimestamp, p.endTimestamp);
        return proposalCounter;
    }

    function vote(uint256 nftId, uint256 proposalId, bool voteFor) public {
        Proposal storage p = proposals[proposalId];
        require(nft.ownerOf(nftId) != address(0), "You must own an NFT to vote");
        require(!p.voters[msg.sender], "You already voted");
        p.voters[msg.sender] = true;
        if (voteFor) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }
        emit Vote(proposalId, msg.sender, voteFor);
    }

    function executeProposal(uint256 proposalId) public onlyOwner{
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.endTimestamp, "Voting is still ongoing");
        require(!p.executed, "Proposal already executed");
        require(p.votesFor > p.votesAgainst, "Proposal did not pass");
        Treasury treasure = Treasury(treasury);
        p.executed = true;
        // treasure.fundTransfer(p.recipient, p.value);
        (bool success, ) = address(treasure).call{value: 0}(abi.encodeWithSignature("fundTransfer(address,uint256)", p.recipient, p.value));
        require(success, "Treasury fund transfer failed");
        emit ProposalExecuted(proposalId);
    }
}