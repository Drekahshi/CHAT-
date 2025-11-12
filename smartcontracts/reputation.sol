
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// Note: This contract depends on CHATToken, so in Remix, deploy CHATToken first and pass its address to the constructor.

/**
 * @title ERC8004ReputationRegistry
 * @dev Tracks agent performance and reputation scores
 */
contract ERC8004ReputationRegistry is Ownable {
    using SafeMath for uint256;
    struct ReputationRecord {
        uint256 tokenId;
        address reviewer;
        uint256 rating; // 0-5 scale
        string feedback;
        uint256 timestamp;
        bool verifiedByHedera;
        string hederaAttestationId;
        uint256 weight;
    }
    struct AggregatedReputation {
        uint256 averageRating;
        uint256 totalInteractions;
        uint256 positiveCount;
        uint256 negativeCount;
        uint256 successRate;
        uint256 overallTrustScore;
        uint256 lastUpdated;
    }
    mapping(uint256 => ReputationRecord[]) public reputationHistory;
    mapping(uint256 => AggregatedReputation) public reputationScores;
    mapping(uint256 => uint256) public totalStaked;
    mapping(uint256 => uint256) public slashingEvents;
    CHATToken public chatToken;
    event ReputationRecorded(
        uint256 indexed tokenId,
        address indexed reviewer,
        uint256 rating
    );
    event ReputationUpdated(uint256 indexed tokenId, uint256 newTrustScore);
    event StakeSlashed(uint256 indexed tokenId, uint256 amount);
    constructor(address _chatToken) {
        chatToken = CHATToken(_chatToken);
    }
    /**
     * @dev Record a reputation entry for an agent
     * @param _tokenId Agent's token ID
     * @param _rating Rating from 0-5
     * @param _feedback Feedback text
     * @param _verifiedByHedera Is this verified by Hedera?
     */
    function recordReputation(
        uint256 _tokenId,
        uint256 _rating,
        string memory _feedback,
        bool _verifiedByHedera
    ) external {
        require(_rating <= 5, "Rating must be 0-5");
        ReputationRecord memory record = ReputationRecord({
            tokenId: _tokenId,
            reviewer: msg.sender,
            rating: _rating,
            feedback: _feedback,
            timestamp: block.timestamp,
            verifiedByHedera: _verifiedByHedera,
            hederaAttestationId: "",
            weight: 100
        });
        reputationHistory[_tokenId].push(record);
        _updateAggregatedReputation(_tokenId);
        emit ReputationRecorded(_tokenId, msg.sender, _rating);
    }
    /**
     * @dev Link Hedera attestation to reputation record
     * @param _tokenId Agent's token ID
     * @param _recordIndex Index of reputation record
     * @param _hederaAttestationId Hedera attestation ID
     */
    function linkHederaAttestation(
        uint256 _tokenId,
        uint256 _recordIndex,
        string memory _hederaAttestationId
    ) external onlyOwner {
        require(_recordIndex < reputationHistory[_tokenId].length, "Invalid record index");
        reputationHistory[_tokenId][_recordIndex].verifiedByHedera = true;
        reputationHistory[_tokenId][_recordIndex].hederaAttestationId = _hederaAttestationId;
    }
    /**
     * @dev Stake CHAT tokens as validator collateral
     * @param _tokenId Agent's token ID
     * @param _amount Amount to stake
     */
    function stakeCollateral(uint256 _tokenId, uint256 _amount) external {
        require(_amount > 0, "Stake must be > 0");
       
        chatToken.transferFrom(msg.sender, address(this), _amount);
        totalStaked[_tokenId] = totalStaked[_tokenId].add(_amount);
    }
    /**
     * @dev Slash agent stake for misbehavior
     * @param _tokenId Agent's token ID
     * @param _amount Amount to slash
     */
    function slashStake(uint256 _tokenId, uint256 _amount) external onlyOwner {
        require(totalStaked[_tokenId] >= _amount, "Insufficient stake");
       
        totalStaked[_tokenId] = totalStaked[_tokenId].sub(_amount);
        slashingEvents[_tokenId] = slashingEvents[_tokenId].add(1);
       
        // Burn slashed tokens
        chatToken.burnTokens(_amount);
       
        emit StakeSlashed(_tokenId, _amount);
        _updateAggregatedReputation(_tokenId);
    }
    /**
     * @dev Update aggregated reputation score
     */
    function _updateAggregatedReputation(uint256 _tokenId) internal {
        ReputationRecord[] memory records = reputationHistory[_tokenId];
        require(records.length > 0, "No reputation records");
        uint256 totalRating = 0;
        uint256 positiveCount = 0;
        uint256 negativeCount = 0;
        for (uint256 i = 0; i < records.length; i++) {
            totalRating = totalRating.add(records[i].rating);
            if (records[i].rating >= 4) {
                positiveCount = positiveCount.add(1);
            } else if (records[i].rating <= 2) {
                negativeCount = negativeCount.add(1);
            }
        }
        uint256 averageRating = totalRating.div(records.length);
        uint256 successRate = (positiveCount * 100) / records.length;
       
        // Calculate trust score (0.0-1.0, represented as 0-1000)
        uint256 trustScore = (successRate * 10).add(
            (averageRating * 100).div(5)
        ).div(2);
        reputationScores[_tokenId] = AggregatedReputation({
            averageRating: averageRating,
            totalInteractions: records.length,
            positiveCount: positiveCount,
            negativeCount: negativeCount,
            successRate: successRate,
            overallTrustScore: trustScore,
            lastUpdated: block.timestamp
        });
        emit ReputationUpdated(_tokenId, trustScore);
    }
    /**
     * @dev Get aggregated reputation
     */
    function getReputation(uint256 _tokenId)
        external
        view
        returns (AggregatedReputation memory)
    {
        return reputationScores[_tokenId];
    }
    /**
     * @dev Get reputation history
     */
    function getReputationHistory(uint256 _tokenId)
        external
        view
        returns (ReputationRecord[] memory)
    {
        return reputationHistory[_tokenId];
    }
}
