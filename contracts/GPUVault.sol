// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";  
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title GPUVault
 * @dev Enhanced vault contract for GPU tokens with cross-user trading support
 * Handles deposits, locking, unlocking, withdrawals, and cross-user balance transfers
 */
contract GPUVault is Ownable, ReentrancyGuard, Pausable {

    using SafeERC20 for IERC20;
    
    IERC20 public immutable gpuToken;

    // User balances
    mapping(address => uint256) public lockedBalances; 
    mapping(address => uint256) public unlockedBalances;
    mapping(address => uint256) public totalDeposited; 

    // Authorized orderbook service address
    address public orderbookAddress;

    // Events
    event Deposit(address indexed user, uint256 amount, uint256 timestamp);
    event Unlock(address indexed user, uint256 amount, uint256 timestamp);
    event Withdraw(address indexed user, uint256 amount, uint256 timestamp);
    event OrderbookUpdated(address indexed oldOrderbook, address indexed newOrderbook);
    event LockedTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);

    // Modifiers
    modifier onlyOrderbook() {
        require(msg.sender == orderbookAddress, "GPUVault: Only Orderbook can call this");
        _;
    }
    
    modifier validAmount(uint256 amount) {
        require(amount > 0, "GPUVault: Amount must be greater than 0");
        _;
    }

    constructor(address _gpuToken) Ownable(msg.sender) {
        require(_gpuToken != address(0), "GPUVault: invalid GPU token address");
        gpuToken = IERC20(_gpuToken);
    }

    /**
     * @dev Deposit GPU tokens to the vault
     * @param amount Amount of GPU tokens to deposit
     */
    function deposit(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        validAmount(amount)
    {
        gpuToken.safeTransferFrom(msg.sender, address(this), amount);

        lockedBalances[msg.sender] += amount;
        totalDeposited[msg.sender] += amount;

        emit Deposit(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Unlock tokens for withdrawal (standard unlock)
     * @param user User address to unlock funds for
     * @param amount Amount to unlock
     */
    function unlock(address user, uint256 amount) 
        external 
        onlyOrderbook 
        validAmount(amount) 
    {
        require(lockedBalances[user] >= amount, "GPUVault: Insufficient locked balance");
        
        lockedBalances[user] -= amount;
        unlockedBalances[user] += amount;
        
        emit Unlock(user, amount, block.timestamp);
    }

    /**
     * @dev Transfer locked balance from one user to another (for cross-chain trading)
     * This enables User A's deposit to be withdrawn by User B after a trade
     * @param from User who is trading away their tokens
     * @param to User who is receiving the tokens  
     * @param amount Amount to transfer
     */
    function transferLocked(address from, address to, uint256 amount) 
        external 
        onlyOrderbook 
        validAmount(amount) 
    {
        require(from != to, "GPUVault: Cannot transfer to self");
        require(lockedBalances[from] >= amount, "GPUVault: Insufficient locked balance");
        
        // Move locked balance from one user to another
        lockedBalances[from] -= amount;
        lockedBalances[to] += amount;
        
        emit LockedTransfer(from, to, amount, block.timestamp);
    }

    /**
     * @dev Combined transfer and unlock in one transaction (gas optimization)
     * Transfers locked balance from one user to another and immediately unlocks it
     * @param from User who is trading away their tokens
     * @param to User who will receive unlocked tokens
     * @param amount Amount to transfer and unlock
     */
    function transferAndUnlock(address from, address to, uint256 amount)
        external 
        onlyOrderbook 
        validAmount(amount) 
    {
        require(from != to, "GPUVault: Cannot transfer to self");
        require(lockedBalances[from] >= amount, "GPUVault: Insufficient locked balance");
        
        // Move locked balance from sender to receiver's unlocked balance
        lockedBalances[from] -= amount;
        unlockedBalances[to] += amount;
        
        emit LockedTransfer(from, to, amount, block.timestamp);
        emit Unlock(to, amount, block.timestamp);
    }

    /**
     * @dev Withdraw unlocked GPU tokens
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        validAmount(amount) 
    {
        require(unlockedBalances[msg.sender] >= amount, "GPUVault: Insufficient unlocked balance");
        
        unlockedBalances[msg.sender] -= amount;
        gpuToken.safeTransfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Set orderbook service address (only owner can call)
     * @param _orderbook Address of the orderbook service wallet
     */
    function setOrderbook(address _orderbook) external onlyOwner {
        require(_orderbook != address(0), "GPUVault: Invalid orderbook address");
        
        address oldOrderbook = orderbookAddress;
        orderbookAddress = _orderbook;
        
        emit OrderbookUpdated(oldOrderbook, _orderbook);
    }

    /**
     * @dev Pause the contract (only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract (only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ================================
    // VIEW FUNCTIONS
    // ================================

    /**
     * @dev Get user's total balance (locked + unlocked)
     * @param user User address
     * @return Total balance
     */
    function getTotalBalance(address user) external view returns (uint256) {
        return lockedBalances[user] + unlockedBalances[user];
    }

    /**
     * @dev Get user's balances breakdown
     * @param user User address  
     * @return locked Locked balance
     * @return unlocked Unlocked balance
     */
    function getBalances(address user) external view returns (uint256 locked, uint256 unlocked) {
        return (lockedBalances[user], unlockedBalances[user]);
    }

    /**
     * @dev Get contract's total GPU token balance (only owner can check)
     * @return Total GPU tokens held by the contract
     */
    function getContractBalance() external view onlyOwner returns (uint256) {
        return gpuToken.balanceOf(address(this));
    }

    /**
     * @dev Check if transfer is possible
     * @param from User address to transfer from
     * @param amount Amount to check
     * @return True if transfer is possible
     */
    function canTransfer(address from, uint256 amount) external view returns (bool) {
        return lockedBalances[from] >= amount;
    }

    /**
     * @dev Check if unlock is possible
     * @param user User address
     * @param amount Amount to check
     * @return True if unlock is possible
     */
    function canUnlock(address user, uint256 amount) external view returns (bool) {
        return lockedBalances[user] >= amount;
    }

    /**
     * @dev Check if withdrawal is possible
     * @param user User address
     * @param amount Amount to check
     * @return True if withdrawal is possible
     */
    function canWithdraw(address user, uint256 amount) external view returns (bool) {
        return unlockedBalances[user] >= amount;
    }
}