// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ERC8004IdentityRegistry
 * @dev Registry for autonomous agent identities using NFTs
 * Each agent receives a unique ERC-721 token with standardized metadata
 */
contract ERC8004IdentityRegistry is ERC721, Ownable {
    using SafeMath for uint256;
    struct AgentProfile {
        string agentName;
        string agentType;
        string metadataURI;
        address operatorWallet;
        uint256 createdAt;
        bool isActive;
        uint256 version;
    }
    struct AgentCapabilities {
        string capabilityName;
        string[] supportedParameters;
        string outputFormat;
        uint256 successMetric;
        uint256 responseTimeMs;
        uint256 costPerOperation;
    }
    uint256 private tokenIdCounter;
    mapping(uint256 => AgentProfile) public agentProfiles;
    mapping(uint256 => AgentCapabilities[]) public agentCapabilities;
    mapping(address => uint256) public operatorToTokenId;
    mapping(uint256 => string) public hederaAccountIds;
    event AgentRegistered(
        uint256 indexed tokenId,
        address indexed operator,
        string agentName,
        string agentType
    );
    event AgentUpdated(uint256 indexed tokenId, uint256 newVersion);
    event CapabilityAdded(uint256 indexed tokenId, string capabilityName);
    event HederaAttestationLinked(uint256 indexed tokenId, string hederaAccountId);
    constructor() ERC721("ERC8004 Agent Identity", "AGENT-ID") {
        tokenIdCounter = 1;
    }
    /**
     * @dev Register a new autonomous agent
     * @param _agentName Human-readable agent name
     * @param _agentType Type of agent (curator, validator, trader, etc.)
     * @param _metadataURI IPFS URI with agent metadata
     * @param _operatorWallet Wallet controlling the agent
     */
    function registerAgent(
        string memory _agentName,
        string memory _agentType,
        string memory _metadataURI,
        address _operatorWallet
    ) external onlyOwner returns (uint256) {
        require(_operatorWallet != address(0), "Invalid operator address");
        require(operatorToTokenId[_operatorWallet] == 0, "Operator already registered");
        uint256 tokenId = tokenIdCounter;
        tokenIdCounter = tokenIdCounter.add(1);
        AgentProfile memory profile = AgentProfile({
            agentName: _agentName,
            agentType: _agentType,
            metadataURI: _metadataURI,
            operatorWallet: _operatorWallet,
            createdAt: block.timestamp,
            isActive: true,
            version: 1
        });
        agentProfiles[tokenId] = profile;
        operatorToTokenId[_operatorWallet] = tokenId;
        _safeMint(_operatorWallet, tokenId);
        emit AgentRegistered(tokenId, _operatorWallet, _agentName, _agentType);
        return tokenId;
    }
    /**
     * @dev Add capability to an agent
     * @param _tokenId Agent's token ID
     * @param _capability Capability details
     */
    function addCapability(
        uint256 _tokenId,
        AgentCapabilities memory _capability
    ) external {
        require(ownerOf(_tokenId) == msg.sender, "Not agent owner");
        require(agentProfiles[_tokenId].isActive, "Agent not active");
        agentCapabilities[_tokenId].push(_capability);
        emit CapabilityAdded(_tokenId, _capability.capabilityName);
    }
    /**
     * @dev Update agent profile version
     * @param _tokenId Agent's token ID
     */
    function updateAgentVersion(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not agent owner");
        agentProfiles[_tokenId].version = agentProfiles[_tokenId].version.add(1);
        emit AgentUpdated(_tokenId, agentProfiles[_tokenId].version);
    }
    /**
     * @dev Link Hedera account to agent for verification
     * @param _tokenId Agent's token ID
     * @param _hederaAccountId Hedera account ID (0.0.XXXXXX format)
     */
    function linkHederaAttestation(uint256 _tokenId, string memory _hederaAccountId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not agent owner");
        hederaAccountIds[_tokenId] = _hederaAccountId;
        emit HederaAttestationLinked(_tokenId, _hederaAccountId);
    }
    /**
     * @dev Get agent profile
     */
    function getAgentProfile(uint256 _tokenId)
        external
        view
        returns (AgentProfile memory)
    {
        return agentProfiles[_tokenId];
    }
    /**
     * @dev Get agent capabilities
     */
    function getAgentCapabilities(uint256 _tokenId)
        external
        view
        returns (AgentCapabilities[] memory)
    {
        return agentCapabilities[_tokenId];
    }
    /**
     * @dev Get token ID by operator wallet
     */
    function getTokenIdByOperator(address _operator) external view returns (uint256) {
        return operatorToTokenId[_operator];
    }
    /**
     * @dev Deactivate agent
     */
    function deactivateAgent(uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "Not agent owner");
        agentProfiles[_tokenId].isActive = false;
    }
}
