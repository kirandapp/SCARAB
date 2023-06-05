// File: contracts/Dao.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IAddressContract.sol";

contract Dao is Ownable{
    IERC20 public token;
    IERC721 public nft;
    address payable public treasury;
    uint256 public proposalCounter = 0;
    uint256 public minVotingTime = 120; // 2 minutes in seconds
    uint256 public maxVotingTime = 86400; //1 day in second
    uint256 public MIN_PROPOSAL_THRESHOLD;
    uint256 public MAX_PROPOSAL_THRESHOLD = 20 ether;   //20000000000000000000; // 20 ETH
    uint256 public MAX_REFUND_TIME = 900; //
    uint256 public voteWeight = 5;

    // uint public minInterest = 10

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
        mapping (address => int) voted;  //-1 against, 1 favor, 0 no vote
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping (uint256 => uint) public proposalActive;

    ////////////////// Judgement structure
    struct SuspectedProposal {   
        bool isGuardianPunished;
        string allegation;
        string explanation;
        bool isSuspected; // whether the guardian is suspected of proposal malpractice
        uint256 votesForJudgement;   //counter track for favor votes
        uint256 votesAgainstJudgement;
        uint256 startTimestamp; //timestamp for when the judgement was created
        uint256 endTimestamp;   //timestamp for when the voting period of judgement ends
        mapping(address => bool) judgementVoters;    //keep track of which guardian vote for judgement
    }

    mapping(uint256 => SuspectedProposal) public judgementProposals;
    mapping(uint256 => uint) private _blacklistedGuardian; // nftId --> proposalId

    event JudgmentProposed(uint256 indexed callerNftId, uint256 indexed guardianNftId, uint256 indexed proposalId, string explanation);
    event JudgmentVoted(uint256 indexed proposalId, bool indexed votesForSupport);
    

    function setContractFactory(IAddressContract _contractFactory) external onlyOwner {
        token = IERC20(_contractFactory.getScarab());
        nft = IERC721(_contractFactory.getScarabNFT());
        treasury = payable(_contractFactory.getTreasury());
    }

    modifier onlyGuardian(uint _guardianId) {
        require(_blacklistedGuardian[_guardianId] == 0, "blacklisted guardian");
        require(nft.ownerOf(_guardianId) == msg.sender, "caller not owner");
        _;
    }

    modifier onlyOwnerOrTreasury() {
        require(msg.sender == owner() || msg.sender == treasury, "Unauthorize!");
        _;
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

    function setMaxRefundTime(uint256 _maxRefundTime) external onlyOwner {
        MAX_REFUND_TIME = _maxRefundTime;
    }

    function setVoteWeight(uint256 _voteWeight) public onlyOwner {
        voteWeight = _voteWeight;
    }

    function getBlackistedProposal(uint _guardianId) external view returns(uint) {
        return _blacklistedGuardian[_guardianId];
    }

    function getActiveProposal(uint _guardianId) external view returns(uint) {
        return proposalActive[_guardianId];
    }
    
    function createProposal(uint256 guardianId, address payable recipient, string memory projectName, string memory description, uint256 value, uint256 refundTime, uint startTime, uint endTime) public onlyGuardian(guardianId) returns (uint256) {

        require(proposalActive[guardianId] == 0, "proposal active!");
        require(value <= MAX_PROPOSAL_THRESHOLD, "Proposal value too high");
         
        uint votingTime = endTime - startTime; 

        require(minVotingTime < votingTime && maxVotingTime > votingTime, "invalid voting time");
        require(MAX_REFUND_TIME > refundTime, "invalid refund Time");

        proposalCounter++; 
        Proposal storage p = proposals[proposalCounter];
        p.id = proposalCounter;
        p.guardianId = guardianId;
        p.recipient = recipient;
        p.projectName = projectName;
        p.description = description;
        p.value = value;        
        p.refundTime = block.timestamp + endTime + refundTime;
        p.startTimestamp = block.timestamp + startTime;
        p.endTimestamp = block.timestamp + endTime;
        emit NewProposal(proposalCounter, guardianId, recipient, projectName, description, value, p.refundTime, p.startTimestamp, p.endTimestamp);
        proposalActive[guardianId] = proposalCounter;
        return proposalCounter;
    }

    function getProposalExecuted(uint256 proposalId) public view returns (bool) {
        return proposals[proposalId].executed;
    }

    function vote(uint256 proposalId, bool voteFor) public {
        require(proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        Proposal storage p = proposals[proposalId];
        require(p.voted[msg.sender] == 0, "You already voted");
        require(!p.executed, "Proposal is executed.");
        require(block.timestamp >= p.startTimestamp && block.timestamp <= p.endTimestamp, "voting not live");
        require(token.balanceOf(msg.sender) >= voteWeight, "You don't have enough tokens to vote.");
        if (voteFor) {
            p.voted[msg.sender] = 1;
            p.votesFor++;
        } else {
            p.voted[msg.sender] = -1;
            p.votesAgainst++;
        }
        emit Vote(proposalId, msg.sender, voteFor);
    }

    function getVotedforProposal(address _voter, uint256 _proposalId) public view returns (int) {
        require(_proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        Proposal storage p = proposals[_proposalId];
        return (p.voted[_voter]);
    }

    function getProposalAmount(uint proposalId) external view returns(uint) {
        require(proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        return proposals[proposalId].value;
    }

    function executeProposal(uint256 proposalId) public  {
        require(proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        Proposal storage p = proposals[proposalId];
        
        SuspectedProposal storage _sp = judgementProposals[proposalId];
        require(!_sp.isSuspected, "can't execute suspected proposal");

        require(block.timestamp >= p.endTimestamp, "Voting is still ongoing");
        require(!p.executed, "Proposal already executed");
       
        if (p.votesFor > p.votesAgainst && p.refundTime > block.timestamp) {
            (bool success, ) = address(treasury).call{value: 0}(abi.encodeWithSignature("fundTransfer(address,uint256)", p.recipient, p.value));
            require(success, "Treasury fund transfer failed");
        }
        else {
            // proposal executed and closed
            proposalActive[p.guardianId] = 0;
        }
        
        p.executed = true;
        emit ProposalExecuted(proposalId);
    }

    function settlementFund(uint256 _proposalId) public payable {
        require(_proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp > p.endTimestamp && block.timestamp < p.refundTime, "no refund time");
        require(msg.value >= p.value, "Not enough amount");
        require(p.executed, "Proposal not executed");

        // close propoasl
        proposalActive[p.guardianId] = 0;
        
        (bool success, ) = address(treasury).call{value: msg.value}(abi.encodeWithSignature("distributeProfit(uint256,uint256)", p.value, msg.value));
        require(success, "Treasury fund transfer failed");
    }
     
    function proposeJudgment(uint256 _proposalId, uint guardianId, string calldata allegation, uint votingTime) public onlyGuardian(guardianId)  {
        require(_proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        require(minVotingTime < votingTime && maxVotingTime > votingTime);

        SuspectedProposal storage _judgementProposal = judgementProposals[_proposalId];  
        Proposal storage _suspectedProposal = proposals[_proposalId]; 
        require(!_judgementProposal.isSuspected, "judgement alreadycreated");
        require(_suspectedProposal.refundTime < block.timestamp, "no refund time");
        
        uint _guardianId = _suspectedProposal.guardianId;
        require(proposalActive[_guardianId] != 0, "proposal already settled");
        _judgementProposal.startTimestamp = block.timestamp;
        _judgementProposal.endTimestamp = block.timestamp + votingTime;
        _judgementProposal.isSuspected = true;
        _judgementProposal.allegation = allegation;

        emit JudgmentProposed(guardianId, _guardianId, _proposalId, allegation);
    }
  
    function explainJudgment(string calldata _explanation, uint _guardianId) external onlyGuardian(_guardianId) {
        uint proposalId = proposalActive[_guardianId];
        require(proposalId != 0, "proposal already settled");
        require(proposalId <= proposalCounter, "Proposal Id doesn't exist!");

        SuspectedProposal storage _judgementProposal = judgementProposals[proposalId];  
        require(_judgementProposal.isSuspected, "guardian is not suspected!");    
        require(block.timestamp < _judgementProposal.endTimestamp, "explaination time over");
        _judgementProposal.explanation = _explanation;
    }
    
    function voteJudgment(uint _proposalId, bool _favourJudment) public {   
        require(token.balanceOf(msg.sender) >= voteWeight, "You don't have enough tokens to vote.");

        require(_proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        SuspectedProposal storage j = judgementProposals[_proposalId];
        require (j.startTimestamp < block.timestamp && j.endTimestamp > block.timestamp, "no time to vote");

        require(j.isSuspected,"guardian is not suspected!");
        require(!j.judgementVoters[msg.sender],"Already voted!");

        if (_favourJudment) {
            j.votesForJudgement++;
        } else {
            j.votesAgainstJudgement++;
        }
        emit JudgmentVoted(_proposalId, _favourJudment);
    }
    
    function processJudgment(uint256 _proposalId) public {
        require(_proposalId <= proposalCounter, "Proposal Id doesn't exist!");
        SuspectedProposal storage j = judgementProposals[_proposalId];

        require (j.endTimestamp < block.timestamp, "voting live");
        require(j.isSuspected,"guardianId is not suspected!");
        require(!j.isGuardianPunished,"Suspected Guardian already punished");

        if (j.votesForJudgement > j.votesAgainstJudgement) {
            j.isGuardianPunished = true;
            _blacklistedGuardian[proposals[_proposalId].guardianId] = _proposalId;
        } else {
            j.isSuspected = false;
        }

        // close proposal
        proposalActive[proposals[_proposalId].guardianId] = 0;
    }

    function unlockBlacklistGuardian(uint _guardianId) external onlyOwnerOrTreasury {
        _blacklistedGuardian[_guardianId] = 0;
    } 
    
}