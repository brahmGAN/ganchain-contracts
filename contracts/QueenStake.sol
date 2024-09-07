// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "./interfaces/IERC721.sol"; 

contract QueenStaking is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors {

    /// @dev Timestamp of the last rewards calculated at 
    uint40 public _lastRewardCalculated; 

    /// @dev Timestamp of staking health last set 
    uint40 public _stakingHealthSetAt; 

    /// @dev The rewards set aside for the entire queen nodes pool per day 
    /// @dev Can hold up to 100 million rewards in GPoints per day, denominated in wei
    uint88 public _rewardsPerDay; 

    /// @dev Instance of the NFT contract that holds the node keys 
    IERC721 public _nftContract; 

    // Not yet finalized 
    mapping(address => uint) _stakingHealth; 

    /// @dev Maps the amount staked by a particular queen node 
    mapping(address => uint88) _stakedAmount;

    /// @dev Total stakes in the staking pool
    /// @dev Can hold upto 10 Billion GPoints in wei 
    uint96 _totalStakes; 

    /// @dev Queen's rewards which is calculated every day
    mapping(address => uint) _queenRewards;

    /// @dev List of queens that stakes
    address[] public _queens; 

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Initializes the contract with GPU contract address and rewards per day for the queen nodes pool.
    /// @dev `rewardsPerDay` should be passed in wei and not as GPoints 
    function initialize(address nftContract, uint256 rewardsPerDay) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _nftContract = IERC721(nftContract);
        _rewardsPerDay = uint88(rewardsPerDay);
        _lastRewardCalculated = uint40(block.timestamp); 
        _stakingHealthSetAt = uint40(block.timestamp);
    }

    /// @notice Minimum staking amount is 1000 GPoints.
    /// @dev Allows the users to stake and become a queen node.
    /// @dev Anyone with the NFT node key can become a queen by staking a minimum of 1000 GPoints initially. 
    function stake() public payable {
        if (_nftContract.balanceOf(msg.sender) < 1) revert BuyNodeNFT();
        if (_stakedAmount[msg.sender] > 0) {
            claimRewards();
        }
        else {
            if (msg.value < 1e21) revert InsufficientStakes();
        }
        _totalStakes += uint96(msg.value); 
        _stakedAmount[msg.sender] += uint88(msg.value); 
        _queens.push(msg.sender);
        //@note emit
    }  

    function claimRewards() public {
        uint rewards = _queenRewards[msg.sender]; 
        if (rewards == 0) revert NoRewards(); 
        _queenRewards[msg.sender] = 0; 
        (bool success,) = payable(msg.sender).call{value: rewards}("");
        if (!success) revert TransferFailed(); 
        //@note emit
    }

    function setStakingHealth(uint[] memory stakingHealth) public onlyOwner {
        if (block.timestamp < _stakingHealthSetAt + 24 hours) revert InComplete24Hours();
        address[] memory queens = _queens; 
        uint queensLength = queens.length; 
        for (uint i = 0; i < queensLength; i++) {
            _stakingHealth[queens[i]] = stakingHealth[i];
        }
        _stakingHealthSetAt = uint40(block.timestamp);
        //@note emit
    }

    function accumulateDailyQueenRewards() public onlyOwner {
        if (block.timestamp < _lastRewardCalculated + 24 hours) revert InComplete24Hours();
        address[] memory queens = _queens; 
        uint totalQueens = queens.length; 
        uint256[] memory stakeScores = new uint256[](totalQueens); 
        uint stakeMultiplier;  
        uint256 totalStakeScore;
        /// @dev Calculates the SS = su * sm * sh 
        for (uint i = 0; i < totalQueens; i++) {
            /// @dev Stores su
            stakeMultiplier = _stakedAmount[_queens[i]];
            /// @dev Calculates the su * sm 
            if (stakeMultiplier < 7000000000000000000000 ) {
                stakeMultiplier *= 125; 
            }
            else if (stakeMultiplier < 25000000000000000000000 ) {
                stakeMultiplier *= 150; 
            }
            else if (stakeMultiplier < 100000000000000000000000) {
                stakeMultiplier *= 175; 
            }
            else {
                stakeMultiplier *= 200; 
            }
            /// @dev Multiplies the already calculated (su * sm) with sh
            stakeScores[i] = stakeMultiplier * _stakingHealth[queens[i]]; 
            /// @dev ∑SS
            totalStakeScore += stakeScores[i]; 
        }
        /// @dev Calculates the queen rewards 
        if (totalStakeScore > 0) {
            uint rewardsPerDay = _rewardsPerDay;
            for (uint i = 0; i < totalQueens; i++) {
                /// @dev queen rewards = (ss * _rewardsPerDay) / ∑SS
                _queenRewards[queens[i]] += (stakeScores[i] * rewardsPerDay) / (totalStakeScore);
            } 
        }
        _lastRewardCalculated = uint40(block.timestamp); 
        // @note emit
    }

    /// @notice No rewards for staking below 1000 GPoints
    /// @dev Allows the queens to unstake 
    function unStake(uint amount) public {
        if (amount == 0) revert ZeroUnstakeAmount();
        if (_stakedAmount[msg.sender] < amount) revert ExceedsStakedAmount();
        claimRewards();
        _stakedAmount[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed(); 
        //@note emit
    }
}