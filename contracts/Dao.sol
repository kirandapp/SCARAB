// File: contracts/Dao.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Treasury.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";


contract Dao is Ownable{
    IERC20 public token;
    IERC721 public nft;
    address payable public treasury;

    uint256 public proposalCounter = 0;
    // uint256 public maxProposalValue = 2000000000000000000; //2eth //20000000000000000000; // 20 ETH
    uint256 public minVotingTime = 120; // 2 minutes in seconds
    uint256 public maxVotingTime = 86400; //1 day in seconds
    uint256 public MIN_PROPOSAL_THRESHOLD;
    uint256 public MAX_PROPOSAL_THRESHOLD = 20 ether;
    uint256 public voteWeight = 5;

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

    function setMinProposalThreshold(uint256 _eth) external onlyOwner {
        MIN_PROPOSAL_THRESHOLD = _eth;
    }
    function setMaxProposalThreshold(uint256 _eth) external onlyOwner {
        MAX_PROPOSAL_THRESHOLD = _eth;
    }
    function setMinVotingTime(uint256 _minTime) external onlyOwner {
        minVotingTime = _minTime;
    }
    function setMaxVotingTime(uint256 _maxTime) external onlyOwner {
        maxVotingTime = _maxTime;
    }
    function setVoteWeight(uint256 _voteWeight) public onlyOwner {
        voteWeight = _voteWeight;
    }

    function createProposal(string memory guardianName, address payable recipient, string memory projectName, string memory description, uint256 value) public returns (uint256) {
        require(value <= MAX_PROPOSAL_THRESHOLD, "Proposal value too high");
        
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
        p.endTimestamp = block.timestamp + minVotingTime;
        emit NewProposal(proposalCounter, guardianName, recipient, projectName, description, value, p.startTimestamp, p.endTimestamp);
        return proposalCounter;
    }

    function vote(uint256 proposalId, bool voteFor) public {
        require(token.approve(address(this), 2**256 - 1));
        Proposal storage p = proposals[proposalId];
        uint256 balance = token.balanceOf(msg.sender);
        require(balance >= 5, "You don't have enough tokens to vote.");
        require(!p.voters[msg.sender], "You already voted");
        p.voters[msg.sender] = true;
        // token.transferFrom(msg.sender, address(this), 1);
        if (voteFor) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }
        emit Vote(proposalId, msg.sender, voteFor);
    }

    function getVoteforProposal(address _voter, uint256 _proposalId) public view returns (bool) {
        Proposal storage p = proposals[_proposalId];
        require(p.voters[_voter], "Not voted yet!");
        if (p.votesFor == 0)
            return false;
        else
            return true;
    }

    function executeProposal(uint256 proposalId) public onlyOwner{
        console.log("6");
        Proposal storage p = proposals[proposalId];
        console.log("7");
        require(block.timestamp >= p.endTimestamp, "Voting is still ongoing");
        console.log("8");
        require(!p.executed, "Proposal already executed");
        console.log("9");
        require(p.votesFor > p.votesAgainst, "Proposal did not pass");
        console.log("10");
        Treasury treasure = Treasury(treasury);
        console.log("11");
        p.executed = true;
        console.log("12");
        // treasure.fundTransfer(p.recipient, p.value);
        (bool success, ) = address(treasure).call{value: 0}(abi.encodeWithSignature("fundTransfer(address,uint256)", p.recipient, p.value));
        console.log("16");
        require(success, "Treasury fund transfer failed");
        console.log("17");
        emit ProposalExecuted(proposalId);
    }

    function settlementFund(uint256 _proposalId) public payable {
        Proposal storage p = proposals[_proposalId];
        require(msg.sender == p.recipient, "You are not the proposee of this proposal");
        uint256 refund = calculateRefund(p.value);
        require(msg.value >= refund, "Not enough amount");
        // (bool success, ) = payable(address(this)).call{value: msg.value}("");
        // require(success, "Transfer Failed!");
    }
    function calculateRefund(uint256 _value) internal pure returns (uint256) {
        _value += _value * 5 / 100;
        return _value;
    }
}