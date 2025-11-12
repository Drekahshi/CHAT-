// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// Note: This contract depends on CHATToken, ERC8004IdentityRegistry, and ERC8004ReputationRegistry. Deploy those first and pass their addresses to the constructor.

/**
 * @title NFTMarketplaceLogic
 * @dev Core marketplace trading logic with agent integration
 */
contract NFTMarketplaceLogic is Ownable {
    using SafeMath for uint256;
    struct NFTListing {
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
        uint256 createdAt;
        uint256 creatorRoyalty;
    }
    struct MarketplaceFee {
        uint256 platformFeePercent; // 2.5% = 250 basis points
        uint256 creatorRoyaltyPercent; // Variable, 0-10%
    }
    CHATToken public chatToken;
    ERC8004IdentityRegistry public identityRegistry;
    ERC8004ReputationRegistry public reputationRegistry;
    uint256 public listingIdCounter;
    mapping(uint256 => NFTListing) public listings;
    mapping(address => uint256[]) public sellerListings;
    mapping(uint256 => bool) public agentApprovedForTrading;
    MarketplaceFee public fees;
    address public treasuryAddress;
    event NFTListed(uint256 indexed listingId, address nftContract, uint256 tokenId);
    event NFTPurchased(
        uint256 indexed listingId,
        address buyer,
        uint256 price,
        bool paidInCHAT
    );
    event RoyaltyPaid(address indexed creator, uint256 amount);
    event AgentApproved(uint256 indexed tokenId, bool approved);
    constructor(
        address _chatToken,
        address _identityRegistry,
        address _reputationRegistry,
        address _treasury
    ) {
        chatToken = CHATToken(_chatToken);
        identityRegistry = ERC8004IdentityRegistry(_identityRegistry);
        reputationRegistry = ERC8004ReputationRegistry(_reputationRegistry);
        treasuryAddress = _treasury;
        fees = MarketplaceFee({
            platformFeePercent: 250, // 2.5%
            creatorRoyaltyPercent: 500 // 5% default
        });
        listingIdCounter = 1;
    }
    /**
     * @dev Approve agent for autonomous trading
     */
    function approveAgentForTrading(uint256 _tokenId) external onlyOwner {
        agentApprovedForTrading[_tokenId] = true;
        emit AgentApproved(_tokenId, true);
    }
    /**
     * @dev List NFT on marketplace
     */
    function listNFT(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        uint256 _creatorRoyalty
    ) external returns (uint256) {
        require(_price > 0, "Price must be > 0");
        require(_creatorRoyalty <= 1000, "Royalty too high (max 10%)");
        uint256 listingId = listingIdCounter;
        listingIdCounter = listingIdCounter.add(1);
        NFTListing memory listing = NFTListing({
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true,
            createdAt: block.timestamp,
            creatorRoyalty: _creatorRoyalty
        });
        listings[listingId] = listing;
        sellerListings[msg.sender].push(listingId);
        emit NFTListed(listingId, _nftContract, _tokenId);
        return listingId;
    }
    /**
     * @dev Purchase NFT with ETH
     */
    function purchaseNFTWithETH(uint256 _listingId) external payable {
        NFTListing storage listing = listings[_listingId];
        require(listing.isActive, "Listing not active");
        require(msg.value >= listing.price, "Insufficient payment");
        _executePurchase(_listingId, false, msg.value);
    }
    /**
     * @dev Purchase NFT with CHAT (gets 2% fee discount)
     */
    function purchaseNFTWithCHAT(uint256 _listingId, uint256 _chatAmount) external {
        NFTListing storage listing = listings[_listingId];
        require(listing.isActive, "Listing not active");
        uint256 ethValue = _convertCHATToETH(_chatAmount);
        require(ethValue >= listing.price, "Insufficient CHAT payment");
        chatToken.transferFrom(msg.sender, address(this), _chatAmount);
        _executePurchase(_listingId, true, ethValue);
    }
    /**
     * @dev Internal purchase execution
     */
    function _executePurchase(
        uint256 _listingId,
        bool _paidInCHAT,
        uint256 _ethValue
    ) internal {
        NFTListing storage listing = listings[_listingId];
        // Calculate fees
        uint256 platformFee = (listing.price * fees.platformFeePercent) / 10000;
        uint256 royaltyAmount = (listing.price * listing.creatorRoyalty) / 10000;
        uint256 sellerProceeds = listing.price.sub(platformFee).sub(royaltyAmount);
        // Apply CHAT discount (2% savings)
        if (_paidInCHAT) {
            platformFee = (platformFee * 60) / 100; // Reduce by 40% = 2% total savings
        }
        // Transfer funds
        (bool treasurySuccess, ) = treasuryAddress.call{value: platformFee}("");
        require(treasurySuccess, "Treasury transfer failed");
        (bool sellerSuccess, ) = listing.seller.call{value: sellerProceeds}("");
        require(sellerSuccess, "Seller transfer failed");
        // Pay creator royalty
        if (royaltyAmount > 0) {
            chatToken.transfer(listing.seller, (royaltyAmount * 1e18) / 1e18);
            emit RoyaltyPaid(listing.seller, royaltyAmount);
        }
        // Mark listing as inactive
        listing.isActive = false;
        emit NFTPurchased(_listingId, msg.sender, listing.price, _paidInCHAT);
    }
    /**
     * @dev Convert CHAT to ETH value (mock oracle)
     */
    function _convertCHATToETH(uint256 _chatAmount) internal pure returns (uint256) {
        // Mock conversion: 1 CHAT = 0.1 ETH
        return (_chatAmount * 1e18) / (10 * 1e18);
    }
    /**
     * @dev Curator agent recommends collection
     */
    function agentRecommendCollection(
        uint256 _agentTokenId,
        uint256[] calldata _listingIds,
        string memory _collectionName,
        string memory _recommendation
    ) external {
        require(agentApprovedForTrading[_agentTokenId], "Agent not approved");
        require(
            reputationRegistry.getReputation(_agentTokenId).overallTrustScore >= 700,
            "Insufficient agent reputation"
        );
        // Reward agent for recommendation
        uint256 reward = 100 * 1e18; // 100 CHAT
        chatToken.transfer(msg.sender, reward);
    }
    /**
     * @dev Fraud detection agent validates NFT
     */
    function agentValidateNFT(
        uint256 _agentTokenId,
        address _nftContract,
        uint256 _tokenId,
        bool _isFraudulent
    ) external returns (bool) {
        require(agentApprovedForTrading[_agentTokenId], "Agent not approved");
        // Stake requirement for fraud claims
        if (_isFraudulent) {
            require(
                reputationRegistry.totalStaked[_agentTokenId] >= 1000 * 1e18,
                "Insufficient agent stake"
            );
        }
        // Log fraud detection
        if (_isFraudulent) {
            // Mark NFT as suspicious in marketplace
            // This would trigger verification process
        }
        return true;
    }
    /**
     * @dev Burn platform fees to support CHAT value
     */
    function burnFeesForDeflationary(uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient balance");
        chatToken.burnTokens(_amount);
    }
    /**
     * @dev Update marketplace fees
     */
    function updateFees(uint256 _platformFee, uint256 _creatorRoyalty) external onlyOwner {
        require(_platformFee <= 1000, "Platform fee too high (max 10%)");
        require(_creatorRoyalty <= 1000, "Creator royalty too high (max 10%)");
        fees.platformFeePercent = _platformFee;
        fees.creatorRoyaltyPercent = _creatorRoyalty;
    }
    /**
     * @dev Get listings by seller
     */
    function getSellerListings(address _seller)
        external
        view
        returns (uint256[] memory)
    {
        return sellerListings[_seller];
    }
    /**
     * @dev Get listing details
     */
    function getListing(uint256 _listingId)
        external
        view
        returns (NFTListing memory)
    {
        return listings[_listingId];
    }
    receive() external payable {}
}
