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

    event NewProposal(uint256 indexed id, uint256 guardianId, address payable recipient, string projectName, string description, uint256 value, uint256 refundTime, uint256 startTimestamp, uint256 endTimestamp);
    event Vote(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event ProposalExecuted(uint256 indexed proposalId);

    struct Proposal {
        uint256 id; //proposal counter is the id
        uint256 guardianId;    //Name of the Guardian
        address payable recipient;  //Guardian Wallet address
        string projectName; //Name of the project
        string description; //project description
        uint256 value;  //fund value  
        uint256 refundTime; //time of return the given value  
        bool executed;  //passed proposal
        uint256 votesFor;   //counter track for favor votes
        uint256 votesAgainst;   //counter track for against votes
        uint256 startTimestamp; //timestamp for when the proposal was created
        uint256 endTimestamp;   //timestamp for when the voting period of proposal end
        mapping(address => bool) voters;    //keep track of which guardian vote for proposal
    }
    mapping(uint256 => Proposal) public proposals;

    ////////////////// Judgement structure
    struct SuspectedGuardian {
        uint256 nftId;
        uint256 proposalId;
        bool isGuardianPunished;
        string explanation;
        // uint256 lockedTokens; // amount of tokens locked by the guardian
        bool isSuspected; // whether the guardian is suspected of proposal malpractice
        uint256 votesForGuardian;   //counter track for favor votes
        uint256 votesAgainstGuardian;
        uint256 startTimestamp; //timestamp for when the proposal was created
        uint256 endTimestamp;   //timestamp for when the voting period of proposal end
        mapping(address => bool) judgementVoters;    //keep track of which guardian vote for proposal
    }
    mapping(uint256 => SuspectedGuardian) public judgementProposals;
    mapping(uint256 => bool) public blackListToUnlock;
    
    event JudgmentProposed(uint256 indexed callerNftId, uint256 indexed guardianNftId, uint256 indexed proposalId, string explanation);
    event JudgmentVoted(uint256 indexed callerNftId, uint256 indexed guardianNftId, bool indexed votesForSupport);
    

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
    function isBlackListToUnlock(uint256 _guardianId) external view returns (bool) {
        return blackListToUnlock[_guardianId];
    }

    function createProposal(uint256 guardianId, address payable recipient, string memory projectName, string memory description, uint256 value, uint256 refundTime) public returns (uint256) {
        (bool success, bytes memory result) = address(nft).call(abi.encodeWithSignature("isGuardian(uint256)", guardianId));
        require(success, "Call failed");
        bool output = abi.decode(result, (bool));
        require(output,"only guardian can create proposal");
        require(value <= MAX_PROPOSAL_THRESHOLD, "Proposal value too high");
        proposalCounter++;
        Proposal storage p = proposals[proposalCounter];
        p.id = proposalCounter;
        p.guardianId = guardianId;
        p.recipient = recipient;
        p.projectName = projectName;
        p.description = description;
        p.value = value;        
        p.refundTime = block.timestamp + refundTime;
        p.executed = false;
        p.startTimestamp = block.timestamp;
        p.endTimestamp = block.timestamp + minVotingTime;
        emit NewProposal(proposalCounter, guardianId, recipient, projectName, description, value, refundTime, p.startTimestamp, p.endTimestamp);
        return proposalCounter;
    }

    function vote(uint256 proposalId, bool voteFor) public {
        console.log("v1");
        require(proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        console.log("v1");
        Proposal storage p = proposals[proposalId];
        console.log("v1");
        require(!p.executed, "Proposal is executed.");
        uint256 balance = token.balanceOf(msg.sender);
        require(balance >= 5, "You don't have enough tokens to vote.");
        require(!p.voters[msg.sender], "You already voted");
        p.voters[msg.sender] = true;
        if (voteFor) {
            p.votesFor++;
        } else {
            p.votesAgainst++;
        }
        emit Vote(proposalId, msg.sender, voteFor);
    }

    function getVoteforProposal(address _voter, uint256 _proposalId) public view returns (bool) {
        require(_proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        Proposal storage p = proposals[_proposalId];
        require(p.voters[_voter], "Not voted yet!");
        if (p.votesFor == 0)
            return false;
        else
            return true;
    }

    function executeProposal(uint256 proposalId) public onlyOwner{
        console.log("6");
        require(proposalId <= proposalCounter, "Proposal Id doesn't exist!");
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
        require(_proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        Proposal storage p = proposals[_proposalId];
        require(msg.sender == p.recipient, "You are not the proposee of this proposal");
        require(block.timestamp < p.refundTime, "refund time has gone!!");
        // uint256 refund = calculateRefund(p.value);
        require(msg.value >= p.value, "Not enough amount");
        // (bool success, ) = payable(address(this)).call{value: msg.value}("");
        // require(success, "Transfer Failed!");
    }
    // function calculateRefund(uint256 _value) internal pure returns (uint256) {
    //     _value += _value * 5 / 100;
    //     return _value;
    // }
    ////////////////////////////////// JUDGEMENT ////////////////////////////////////

    
    
    function proposeJudgment(uint256 _guardianId, uint256 proposalId, string calldata explanation) public {
        SuspectedGuardian storage j = judgementProposals [_guardianId];
        Proposal storage p = proposals[proposalId];
        // require(nft.isGuardian[_guardianId],"guardian not exist!!");
        (bool success, bytes memory result) = address(nft).call(abi.encodeWithSignature("isGuardian(uint256)", _guardianId));
        require(success, "Call failed");
        bool output = abi.decode(result, (bool));
        require(output,"guardian not exist!!");
        uint256 callerGuardianId = nft.balanceOf(msg.sender);
        // require(nft.isGuardian[callerGuardianId],"caller is not a guardian!!");
        (success, result) = address(nft).call(abi.encodeWithSignature("isGuardian(uint256)", callerGuardianId));
        require(success, "Call failed");
        output = abi.decode(result, (bool));
        require(output,"caller is not a guardian!!");
        require(!p.executed,"Project Proposal executed!");
        SuspectedGuardian storage s = judgementProposals [callerGuardianId]; 
        require(!s.isSuspected,"suspected guardian can't propose judgement.");
        require(!j.isSuspected, "requested Guardian is already suspected.");
        j.nftId = _guardianId;
        j.proposalId = proposalId;
        j.explanation = explanation;
        j.isSuspected = true;
        j.startTimestamp = block.timestamp;
        j.endTimestamp = block.timestamp + minVotingTime;
        emit JudgmentProposed(callerGuardianId, _guardianId, proposalId, explanation);
    }
    
    function voteJudgment(uint256 _guardianId, bool votesForGuardian) public {
        uint256 callerGuardianId = nft.balanceOf(msg.sender);
        // require(!nft.isGuardian[callerGuardianId],"guardian can't vote!!");
        (bool success, bytes memory result) = address(nft).call(abi.encodeWithSignature("isGuardian(uint256)", callerGuardianId));
        require(success, "Call failed");
        bool output = abi.decode(result, (bool));
        require(!output,"guardian can't vote!!");
        SuspectedGuardian storage j = judgementProposals [_guardianId];
        require(j.isSuspected,"guardian is not suspected!!");
        require(!j.judgementVoters[msg.sender],"Already voted!");
        if (votesForGuardian) {
            j.votesForGuardian++;
        } else {
            j.votesAgainstGuardian++;
        }
        emit JudgmentVoted(callerGuardianId, _guardianId, votesForGuardian);
    }
    
    function processJudgment(uint256 _guardianId) public onlyOwner {
        SuspectedGuardian storage j = judgementProposals [_guardianId];
        require(j.isSuspected,"guardianId is not suspected!");
        require(!j.isGuardianPunished,"Suspected Guardian already punished");
        if (j.votesForGuardian > j.votesAgainstGuardian) {
            j.isGuardianPunished = true;
            blackListToUnlock[_guardianId] = true;
            console.log("checkforBlacklist",blackListToUnlock[_guardianId]);
        } else {
            j.isSuspected = false;
        }
    }
    
}
