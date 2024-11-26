// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "./interfaces/IQueenStake.sol"; 
import "./GPU/GPU.sol";

contract QueenStaking is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors,IQueenStake {

    /// @dev Timestamp of the last rewards calculated at 
    uint40 _lastRewardCalculated; 

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
    address[] _queens; 

    /// @dev instance of the GPU contract
    GPU public GPUInstance;

    /// @dev switch to control open rewards 
    bool public _openRewards; 

    /// @dev Checkes whether the user has already enrolled for the queen rewards
    mapping(address => bool) _enrolledForQueen;

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Initializes the contract with GPU contract address and rewards per day for the queen nodes pool.
    /// @dev `rewardsPerDay` should be passed in wei and not as GPoints 
    function initialize(address gpuContract, address nftContract, uint256 rewardsPerDay) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _nftContract = IERC721(nftContract);
        _rewardsPerDay = uint88(rewardsPerDay);
        GPUInstance = GPU(gpuContract);
    }

    /// @notice No minimum staking amount 
    /// @dev Allows the users to stake and become a queen node.
    /// @dev Anyone with the NFT node key can become a queen by staking a minimum of 1000 GPoints initially. 
    function stake() external  payable {
        if (_nftContract.balanceOf(msg.sender) < 1) revert BuyNodeNFT();
        if (_stakedAmount[msg.sender] > 0) {
            if (_queenRewards[msg.sender] > 0) {
                claimRewards();
            }
        }
        _totalStakes += uint96(msg.value); 
        _stakedAmount[msg.sender] += uint88(msg.value); 
        if(!_enrolledForQueen[msg.sender]) {
            _queens.push(msg.sender);
            _enrolledForQueen[msg.sender] = true; 
        }
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

    function accumulateDailyQueenRewards() public onlyOwner {
        /// @dev Removed this check to keep things flexible. 
        //if (block.timestamp < _lastRewardCalculated + 24 hours) revert InComplete24Hours();
        address[] memory queens = _queens; 
        uint24 totalQueens = uint24(queens.length); 
        uint96[] memory stakeScores = new uint96[](totalQueens); 
        uint96 stakeMultiplier;  
        uint96 totalStakeScore;
        /// @dev Calculates the SS = su * sm 
        for (uint i = 0; i < totalQueens; i++) {

           /// @dev This check makes sure rewards are handed out only if validators and queens are still setup. It's done as the first step of the loop.
           /// @dev If this check fails then we iterate to the next address. 
           // if(GPUInstance.isValidator(queens[i]) || GPUInstance.isQueen(queens[i]))
           /// @dev Stores su
                if(_openRewards && GPUInstance.isValidator(queens[i]))
                {
                    stakeMultiplier = _stakedAmount[queens[i]] + 1e20;
                }
                else 
                {
                    stakeMultiplier = _stakedAmount[queens[i]];
                }

                /// @dev Staking multilpier 
                /// @dev Calculates the (su * sm) 
                if (stakeMultiplier <= 1e20) {
                    stakeMultiplier = stakeMultiplier; 
                }
                else if (stakeMultiplier <= 1e21) {
                    stakeMultiplier *= 125; 
                }
                else if (stakeMultiplier <= 7e21) {
                    stakeMultiplier *= 150; 
                }
                else if (stakeMultiplier <= 25e21) {
                    stakeMultiplier *= 175; 
                }
                else {
                    stakeMultiplier *= 200; 
                }

                /// @dev Multiplies the already calculated (su * sm) with sh and comepletes calculating the SS = su * sm * sh 
                // Currently the staking health is 1
                // stakeScores[i] = stakeMultiplier * stakingHealth[i]; 
                stakeScores[i] = stakeMultiplier; 

                /// @dev ∑SS
                totalStakeScore += stakeScores[i]; 
        }

        /// @dev This check makes sure rewards are handed out only if validators and queens are still setup. It's done as the first step of the loop.
        /// @dev If this check fails then we iterate to the next address. 
        // if(GPUInstance.isValidator(queens[i]) || GPUInstance.isQueen(queens[i]))    
        /// @dev Calculates the queen rewards 
        /// @dev (ss/∑ss) * Rewards per day
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
    function unStake(uint88 amount) public {
        if (amount == 0) revert ZeroUnstakeAmount();
        if (_stakedAmount[msg.sender] < amount) revert ExceedsStakedAmount();
        if (_queenRewards[msg.sender] > 0) {
            claimRewards();
        }
        _stakedAmount[msg.sender] -= amount;
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed(); 
        emit unStaked(msg.sender, amount);
    }

    /// @dev set `_openRewards` 
    function setOpenRewards(bool status) external onlyOwner() {
        _openRewards = status; 
    }

    /// @dev Registered validators can enroll for queen rewards if the switch is on
    function validatorRewardsEnroll(address validator) external onlyOwner() {
        if (_openRewards && GPUInstance.isValidator(validator) && !_enrolledForQueen[validator]) {
            _queens.push(validator); 
            _enrolledForQueen[validator] = true; 
        }
        emit validatorEnrolled(validator);
    }

    /// @dev set the rewards per day for queen's
    function setRewardsPerDay(uint88 rewardsPerDay) external {
        _rewardsPerDay = rewardsPerDay;  
    }

    /// @notice Getter functions
    
    function getLastRewardCalculated() external view onlyOwner() returns(uint40) {
        return _lastRewardCalculated;
    }

    function getStakedAmount(address queen) external view onlyOwner() returns(uint88) {
        return _stakedAmount[queen]; 
    } 

    function getMyStakedAmount() external view returns(uint88) {
        return _stakedAmount[msg.sender]; 
    }

    function getTotalStakes() external view onlyOwner() returns(uint96) {
        return _totalStakes;
    }

    function getQueenRewards(address queen) external view onlyOwner() returns(uint96) {
        return _queenRewards[queen]; 
    } 

    function getMyRewards() external view returns(uint96) {
        return _queenRewards[msg.sender]; 
    }

    function getAllQueens() external view returns(address[] memory) {
        return _queens; 
    }

    function getOpenRewardStatus() external view returns(bool) {
        return _openRewards; 
    }
}