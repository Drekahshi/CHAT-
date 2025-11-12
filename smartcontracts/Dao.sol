
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// Note: This contract depends on CHATToken, so in Remix, deploy CHATToken first and pass its address to the constructor.

/**
 * @title DAOGovernance
 * @dev Decentralized governance for marketplace decisions
 */
contract DAOGovernance is Ownable {
    using SafeMath for uint256;
    enum ProposalStatus {
        PENDING,
        ACTIVE,
        EXECUTED,
        REJECTED,
        CANCELLED
    }
    struct Proposal {
        uint256 proposalId;
        string description;
        string ipfsHash; // Link to full proposal details
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        ProposalStatus status;
        address proposer;
        bool executed;
    }
    CHATToken public chatToken;
    uint256 public proposalCounter;
    uint256 public votingPeriod = 7 days;
    uint256 public proposalThreshold = 10000 * 1e18; // 10K CHAT to propose
    uint256 public quorumPercentage = 50; // 50%
    uint256 public majorityPercentage = 66; // 66%
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    mapping(uint256 => mapping(address => uint256)) public votePower;
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description
    );
    event VoteCasted(
        uint256 indexed proposalId,
        address indexed voter,
        bool support,
        uint256 power
    );
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalRejected(uint256 indexed proposalId);
    constructor(address _chatToken) {
        chatToken = CHATToken(_chatToken);
        proposalCounter = 1;
    }
    /**
     * @dev Create new governance proposal
     */
    function createProposal(
        string memory _description,
        string memory _ipfsHash
    ) external returns (uint256) {
        require(
            chatToken.balanceOf(msg.sender) >= proposalThreshold,
            "Insufficient CHAT to propose"
        );
        uint256 proposalId = proposalCounter;
        proposalCounter = proposalCounter.add(1);
        Proposal memory proposal = Proposal({
            proposalId: proposalId,
            description: _description,
            ipfsHash: _ipfsHash,
            startTime: block.timestamp,
            endTime: block.timestamp.add(votingPeriod),
            forVotes: 0,
            againstVotes: 0,
            status: ProposalStatus.ACTIVE,
            proposer: msg.sender,
            executed: false
        });
        proposals[proposalId] = proposal;
        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }
    /**
     * @dev Vote on proposal
     */
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal not active");
        require(block.timestamp <= proposal.endTime, "Voting period ended");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");
        uint256 voteWeight = chatToken.balanceOf(msg.sender);
        require(voteWeight > 0, "No CHAT to vote with");
        hasVoted[_proposalId][msg.sender] = true;
        votePower[_proposalId][msg.sender] = voteWeight;
        if (_support) {
            proposal.forVotes = proposal.forVotes.add(voteWeight);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(voteWeight);
        }
        emit VoteCasted(_proposalId, msg.sender, _support, voteWeight);
    }
    /**
     * @dev Finalize proposal after voting period
     */
    function finalizeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.ACTIVE, "Proposal not active");
        require(block.timestamp > proposal.endTime, "Voting still ongoing");
        uint256 totalVotes = proposal.forVotes.add(proposal.againstVotes);
        uint256 totalChatSupply = chatToken.totalSupply();
        uint256 quorumNeeded = (totalChatSupply * quorumPercentage) / 100;
        // Check quorum
        if (totalVotes < quorumNeeded) {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalRejected(_proposalId);
            return;
        }
        // Check majority
        uint256 majorityNeeded = (totalVotes * majorityPercentage) / 100;
        if (proposal.forVotes >= majorityNeeded) {
            proposal.status = ProposalStatus.EXECUTED;
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.REJECTED;
            emit ProposalRejected(_proposalId);
        }
    }
    /**
     * @dev Get proposal details
     */
    function getProposal(uint256 _proposalId)
        external
        view
        returns (Proposal memory)
    {
        return proposals[_proposalId];
    }
    /**
     * @dev Update voting parameters
     */
    function updateVotingParameters(
        uint256 _votingPeriod,
        uint256 _quorumPercentage,
        uint256 _majorityPercentage
    ) external onlyOwner {
        require(_quorumPercentage <= 100, "Invalid quorum");
        require(_majorityPercentage <= 100, "Invalid majority");
        votingPeriod = _votingPeriod;
        quorumPercentage = _quorumPercentage;
        majorityPercentage = _majorityPercentage;
    }
}
