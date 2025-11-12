// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title CHATToken
 * @dev CHAT is the native utility token of NFT Museum Marketplace
 * Features: Minting, burning, staking, and deflationary mechanics
 */
contract CHATToken is ERC20, ERC20Burnable, Ownable, Pausable {
    using SafeMath for uint256;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion
    uint256 public totalBurned;
   
    // Treasury and staking
    address public treasuryAddress;
    mapping(address => uint256) public stakedBalance;
    uint256 public totalStaked;
    // Minting allocation tracking
    bool public mintingComplete;
    uint256 public allocatedCommunity;
    uint256 public allocatedTeam;
    uint256 public allocatedTreasury;
    event TokensMinted(address indexed to, uint256 amount, string category);
    event TokensStaked(address indexed user, uint256 amount);
    event TokensUnstaked(address indexed user, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    constructor(address _treasuryAddress) ERC20("CHAT", "CHAT") {
        treasuryAddress = _treasuryAddress;
       
        // Initial allocation
        allocatedCommunity = 400_000_000 * 10 ** 18;
        allocatedTeam = 300_000_000 * 10 ** 18;
        allocatedTreasury = 300_000_000 * 10 ** 18;
    }
    /**
     * @dev Mint tokens for community distribution
     * @param _to Address receiving tokens
     * @param _amount Amount to mint
     */
    function mintCommunity(address _to, uint256 _amount) external onlyOwner {
        require(!mintingComplete, "Minting complete");
        require(allocatedCommunity >= _amount, "Exceeds community allocation");
        require(totalSupply().add(_amount) <= MAX_SUPPLY, "Exceeds max supply");
       
        _mint(_to, _amount);
        allocatedCommunity = allocatedCommunity.sub(_amount);
        emit TokensMinted(_to, _amount, "COMMUNITY");
    }
    /**
     * @dev Mint tokens for team (vested allocation)
     * @param _to Address receiving tokens
     * @param _amount Amount to mint
     */
    function mintTeam(address _to, uint256 _amount) external onlyOwner {
        require(!mintingComplete, "Minting complete");
        require(allocatedTeam >= _amount, "Exceeds team allocation");
        require(totalSupply().add(_amount) <= MAX_SUPPLY, "Exceeds max supply");
       
        _mint(_to, _amount);
        allocatedTeam = allocatedTeam.sub(_amount);
        emit TokensMinted(_to, _amount, "TEAM");
    }
    /**
     * @dev Mint tokens for treasury
     * @param _to Address receiving tokens
     * @param _amount Amount to mint
     */
    function mintTreasury(address _to, uint256 _amount) external onlyOwner {
        require(!mintingComplete, "Minting complete");
        require(allocatedTreasury >= _amount, "Exceeds treasury allocation");
        require(totalSupply().add(_amount) <= MAX_SUPPLY, "Exceeds max supply");
       
        _mint(_to, _amount);
        allocatedTreasury = allocatedTreasury.sub(_amount);
        emit TokensMinted(_to, _amount, "TREASURY");
    }
    /**
     * @dev Finalize minting - no more tokens can be created
     */
    function finalizeMinting() external onlyOwner {
        mintingComplete = true;
    }
    /**
     * @dev Stake CHAT tokens to earn rewards
     * @param _amount Amount to stake
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
       
        transfer(address(this), _amount);
        stakedBalance[msg.sender] = stakedBalance[msg.sender].add(_amount);
        totalStaked = totalStaked.add(_amount);
       
        emit TokensStaked(msg.sender, _amount);
    }
    /**
     * @dev Unstake CHAT tokens
     * @param _amount Amount to unstake
     */
    function unstake(uint256 _amount) external {
        require(_amount > 0, "Cannot unstake 0");
        require(stakedBalance[msg.sender] >= _amount, "Insufficient staked balance");
       
        stakedBalance[msg.sender] = stakedBalance[msg.sender].sub(_amount);
        totalStaked = totalStaked.sub(_amount);
        _transfer(address(this), msg.sender, _amount);
       
        emit TokensUnstaked(msg.sender, _amount);
    }
    /**
     * @dev Burn tokens to reduce supply (deflationary mechanism)
     * @param _amount Amount to burn
     */
    function burnTokens(uint256 _amount) external {
        require(balanceOf(msg.sender) >= _amount, "Insufficient balance");
        _burn(msg.sender, _amount);
        totalBurned = totalBurned.add(_amount);
        emit TokensBurned(msg.sender, _amount);
    }
    /**
     * @dev Pause/unpause token transfers
     */
    function pauseTransfers() external onlyOwner {
        _pause();
    }
    function unpauseTransfers() external onlyOwner {
        _unpause();
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
