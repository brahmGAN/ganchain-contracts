// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "./interfaces/IQueenStake.sol"; 
import "./interfaces/IERC721.sol";

contract QueenStaking is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors,IQueenStake {

    /// @dev Timestamp of the last rewards calculated at 
    uint40 public _lastRewardCalculated; 

    /// @dev The rewards set aside for the entire queen nodes pool per day 
    /// @dev Can hold up to 100 million rewards in GPoints per day, denominated in wei
    uint88 public _rewardsPerDay; 

    /// @dev Instance of the NFT contract that holds the node keys 
    IERC721 public _nftContract; 

    /// @dev Maps the amount staked by a particular queen node 
    mapping(address => uint88) _stakedAmount;

    /// @dev Total stakes in the staking pool
    /// @dev Can hold upto 10 Billion GPoints in wei 
    uint96 _totalStakes; 

    /// @dev Queen's rewards which is calculated every day
    mapping(address => uint96) _queenRewards;

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
    }

    /// @notice Minimum staking amount is 1000 GPoints.
    /// @dev Allows the users to stake and become a queen node.
    /// @dev Anyone with the NFT node key can become a queen by staking a minimum of 1000 GPoints initially. 
    function stake() public payable {
        if (_nftContract.balanceOf(msg.sender) < 1) revert BuyNodeNFT();
        if (_queenRewards[msg.sender] > 0) {
            claimRewards();
        }
        else {
            if (msg.value < 1e21) revert InsufficientStakes();
        }
        _totalStakes += uint96(msg.value); 
        _stakedAmount[msg.sender] += uint88(msg.value); 
        _queens.push(msg.sender);
        emit staked(msg.sender, uint88(msg.value));
    }  

    function claimRewards() public {
        uint96 rewards = _queenRewards[msg.sender]; 
        if (rewards == 0) revert NoRewards(); 
        _queenRewards[msg.sender] = 0; 
        (bool success,) = payable(msg.sender).call{value: rewards}("");
        if (!success) revert TransferFailed(); 
        emit claimedRewards(msg.sender, rewards);
    }

    function accumulateDailyQueenRewards(uint[] calldata stakingHealth) public onlyOwner {
        if (block.timestamp < _lastRewardCalculated + 24 hours) revert InComplete24Hours();
        address[] memory queens = _queens; 
        uint256 totalQueens = queens.length; 
        uint256[] memory stakeScores = new uint256[](totalQueens); 
        uint256 stakeMultiplier;  
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
            stakeScores[i] = stakeMultiplier * stakingHealth[i]; 
            /// @dev ∑SS
            totalStakeScore += stakeScores[i]; 
        }
        /// @dev Calculates the queen rewards 
        if (totalStakeScore > 0) {
            uint256 rewardsPerDay = _rewardsPerDay;
            for (uint i = 0; i < totalQueens; i++) {
                /// @dev queen rewards = (ss * _rewardsPerDay) / ∑SS
                _queenRewards[queens[i]] += uint96((stakeScores[i] * rewardsPerDay) / (totalStakeScore));
            } 
        }
        _lastRewardCalculated = uint40(block.timestamp); 
        emit accumulatedDailyQueenRewards(_lastRewardCalculated);
    }

    /// @notice No rewards for staking below 1000 GPoints
    /// @dev Allows the queens to unstake 
    function unStake(uint amount) public {
        if (amount == 0) revert ZeroUnstakeAmount();
        if (_stakedAmount[msg.sender] < amount) revert ExceedsStakedAmount();
        if (_queenRewards[msg.sender] > 0) {
            claimRewards();
        }
        _stakedAmount[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed(); 
        emit unStaked(msg.sender, amount);
    }
}