// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "./interfaces/IQueenStake.sol"; 
import "./GPU/GPU.sol";

contract NewQueenStaking is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors,IQueenStake {

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

    /// @dev Pending Queen's rewards 
    mapping(address => uint96) _pendingQueenRewards;

    /// @dev Total earned rewards of the queen 
    mapping(address => uint96) _totalRewardsEarned;

    /// @dev List of queens that stakes
    address[] _queens; 

    /// @dev instance of the GPU contract
    GPU public GPUInstance;

    /// @dev switch to control open rewards 
    bool public _openRewards; 

    /// @dev Checkes whether the user has already enrolled for the queen rewards
    mapping(address => bool) _enrolledForQueen;

    /// @dev Boolean switch to control the availability of stake() 
    bool public _stake;

    /// @dev Boolean switch to control the availability of unStake()
    bool public _unStake;

    /// @dev Boolean switch to control the availability of claim()
    bool public _claim; 

    /// @dev Mapping that stores the rewards claimed by a user so far
    mapping(address => uint96) _totalRewardsclaimed; 

    mapping(address => uint88) public _unUsedStakes; 

    mapping(address => uint88) public _castedVotes;

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
        //if (_nftContract.balanceOf(msg.sender) < 1) revert BuyNodeNFT();
        if (!_stake) revert stakeNotYetAvailable(); 
        // if (_stakedAmount[msg.sender] > 0) {
            // if (_pendingQueenRewards[msg.sender] > 0) {
            //     claimRewards();
            // }
        // }
        _totalStakes += uint96(msg.value); 
        _stakedAmount[msg.sender] += uint88(msg.value); 
        _unUsedStakes[msg.sender] += uint88(msg.value); 
        if(!_enrolledForQueen[msg.sender]) {
            _queens.push(msg.sender);
            _enrolledForQueen[msg.sender] = true; 
        }
        emit newstaked(msg.sender, uint88(msg.value), _stakedAmount[msg.sender], _unUsedStakes[msg.sender], _totalStakes);  //TODO: emit  uncastedvotes 1
    }  

    /// @notice No rewards for staking below 1000 GPoints
    /// @dev Allows the queens to unstake 
    function unStake(uint88 amount) public {
        if (!_unStake) revert unStakeNotYetAvailable();
        if (amount == 0) revert ZeroUnstakeAmount();
        if (_unUsedStakes[msg.sender] < amount) revert ExceedsStakedAmount(); //TODO: instead of uncastedVotes use unusedStake 2
        _stakedAmount[msg.sender] -= amount; 
        _unUsedStakes[msg.sender] -= amount;    //TODO: recalculate and update unusedStake 3
        _totalStakes -= amount; 
        (bool success,) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed(); 
        emit unStaked(msg.sender, amount);
    }

    // /// @dev call this function first before accumulateDailyQueenRewards is called
    // function setCastedVotes(address[] memory queens, uint88[] memory castedVotes) external onlyOwner { //TODO: merge this function with accumulateDailyQueenRewards 8
    //     // : check if the length of both arrays are equal 5
    //     if (_queens.length != queensPassed.length) revert incorrectArraySize();

    //     uint88 skipped; 
    //     address[] memory skippedQueens; 

    //     for(uint i = 0; i < queensPassed.length; i++) 
    //     {
    //         // : if queen[i] doesnt exist in the _queens then skip it (also maintain the skip counter and emit it later) 6
    //         // : also check if castedVotes * 1 eth <= stakedAmount (if not then again skip it and add it to skip counter) 7
    //         if (_enrolledForQueen[queensPassed[i]] && ((castedVotes[i] * 1 ether) <= _stakedAmount[queensPassed[i]])) 
    //         {
    //             _castedVotes[queensPassed[i]] = castedVotes[i]; 
    //             _unUsedStakes[queensPassed[i]] = _stakedAmount[queensPassed[i]] - (castedVotes[i] * 1 ether); //: stakedAmount - (castedVotes * 1 eth) && change uncastedVotes to unusedStake 4
    //         }
    //         else 
    //         {
    //             skippedQueens[skipped] = queensPassed[i];
    //             skipped++; 
    //         }
    //     } 
    // }

    function accumulateDailyQueenRewards(address[] memory queensPassed, uint88[] memory castedVotes) public onlyOwner {
        /// @dev Removed this check to keep things flexible. 
        //if (block.timestamp < _lastRewardCalculated + 24 hours) revert InComplete24Hours();
        address[] memory queens = _queens; 
        uint24 totalQueens = uint24(queens.length); 
        uint96[] memory stakeScores = new uint96[](totalQueens); 
        uint96 stakeMultiplier;  
        uint96 totalStakeScore;

        // TODO: check if the length of both arrays are equal 5
        if (_queens.length != queensPassed.length) revert incorrectArraySize();

        uint88 skipped; 
        address[] memory skippedQueens; 

        for(uint i = 0; i < queensPassed.length; i++) 
        {
            // TODO: if queen[i] doesnt exist in the _queens then skip it (also maintain the skip counter and emit it later) 6
            // TODO: also check if castedVotes * 1 eth <= stakedAmount (if not then again skip it and add it to skip counter) 7
            if (_enrolledForQueen[queensPassed[i]] && ((castedVotes[i] * 1 ether) <= _stakedAmount[queensPassed[i]])) 
            {
                _castedVotes[queensPassed[i]] = castedVotes[i]; 
                _unUsedStakes[queensPassed[i]] = _stakedAmount[queensPassed[i]] - (castedVotes[i] * 1 ether); //TODO: stakedAmount - (castedVotes * 1 eth) && change uncastedVotes to unusedStake 4
            }
            else 
            {
                skippedQueens[skipped] = queensPassed[i];
                skipped++; 
            }
        } 

        /// @dev Calculates the SS = su * sm 
        for (uint i = 0; i < totalQueens; i++) {

                //stakeMultiplier = _castedVotes[queens[i]]; //TODO: Remove this 9
                
                if (_stakedAmount[queens[i]] <= 1e20) {  //TODO: change it to if(_stakedAmount[queens[i]] <= 1e20) and then update the stakeMultiplier as follows: 10
                    stakeMultiplier = 100; //TODO: stakeMultiplier = 100; 11
                }
                else if (_stakedAmount[queens[i]] <= 1e21) {
                    stakeMultiplier = 125;  //TODO: stakeMultiplier = 125; 12
                }
                else if (_stakedAmount[queens[i]] <= 7e21) {
                    stakeMultiplier = 150; 
                }
                else if (_stakedAmount[queens[i]] <= 25e21) {
                    stakeMultiplier = 175; 
                }
                else {
                    stakeMultiplier = 200; 
                }

                stakeScores[i] = _castedVotes[queens[i]] * stakeMultiplier;  //TODO: stakeScore = _castedVotes[queens[i]] * stakeMultiplier; 13

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
            uint96 newRewards; 
            for (uint i = 0; i < totalQueens; i++) {
                /// @dev queen rewards = (ss * _rewardsPerDay) / ∑SS
                newRewards = uint96((stakeScores[i] * rewardsPerDay) / (totalStakeScore));
                // _pendingQueenRewards[queens[i]] +=  newRewards; 
                _totalRewardsEarned[queens[i]] += newRewards; 
                _stakedAmount[queens[i]] += uint88(newRewards); 
            } 
        }
        _lastRewardCalculated = uint40(block.timestamp); 
        emit newAccumulatedDailyQueenRewards(_lastRewardCalculated, skipped, skippedQueens); //TODO: add the skip counter from setCastedVotes 14
    }

    /// @dev set `_openRewards` 
    function setOpenRewards(bool status) external onlyOwner {
        _openRewards = status; 
    }

    /// @dev Registered validators can enroll for queen rewards if the switch is on
    function validatorRewardsEnroll(address validator) external onlyOwner {
        if (_openRewards && GPUInstance.isValidator(validator) && !_enrolledForQueen[validator]) {
            _queens.push(validator); 
            _enrolledForQueen[validator] = true; 
        }
        emit validatorEnrolled(validator);
    }

    /// @dev set the rewards per day for queen's
    function setRewardsPerDay(uint88 rewardsPerDay) external onlyOwner {
        _rewardsPerDay = rewardsPerDay;  
    }

    /// @dev Set the status of the functions that users interact with. 
    function setUserFunctionStatus(bool status, uint8 functionType) external onlyOwner {

        /// @dev sets the status of stake(), functionType = 0
        if (functionType == 0) {
            _stake = status; 
        }

        /// @dev sets the status of unStake(), functionType = 1
        else if (functionType == 1) {
            _unStake = status;
        }

        /// @dev sets the status of claim(), functionType = 2 //TODO: remove since claim is removed 15
        // else if (functionType == 2) {
        //     _claim = status;
        // }

        else {
            revert wrongFunctionType(); 
        }
    }

    /// @dev Set the total rewards claimed by the queens so far 
    function setTotalRewardsClaimed(address queen, uint96 rewardsClaimed) external onlyOwner {
        _totalRewardsclaimed[queen] = rewardsClaimed; 
    }

    function authorizedUnstake(address queen) external onlyOwner {
        //uint96 rewards = _pendingQueenRewards[msg.sender]; //TODO: instead of pendingRewards, use stakedAmount 16
        uint96 stakedAmount = _stakedAmount[msg.sender]; 

        //_pendingQueenRewards[msg.sender] = 0;
        //_totalRewardsclaimed[msg.sender] += rewards;

        _stakedAmount[msg.sender] = 0;
        _totalStakes -= stakedAmount; 

        (bool success,) = payable(queen).call{value: (stakedAmount)}(""); //TODO: send to queen address directly 17
        if (!success) revert TransferFailed(); 
        emit authorizedUnStaked(queen, (stakedAmount));
    }

    /// @notice Getter functions
    
    function getLastRewardCalculated() external view onlyOwner returns(uint40) {
        return _lastRewardCalculated;
    }

    function getStakedAmount(address queen) external view onlyOwner returns(uint88) {
        return _stakedAmount[queen]; 
    } 

    function getMyStakedAmount() external view returns(uint88) {
        return _stakedAmount[msg.sender]; 
    }

    function getTotalStakes() external view onlyOwner returns(uint96) {
        return _totalStakes;
    }

    function getQueenRewards(address queen) external view onlyOwner returns(uint96) {
        return _pendingQueenRewards[queen]; 
    } 

    function getMyPendingRewards() external view returns(uint96) {
        return _pendingQueenRewards[msg.sender]; 
    }

    function getMyTotalRewardsEarned() external view returns(uint96) {
        return _totalRewardsEarned[msg.sender]; 
    }

    function getAllQueens() external view returns(address[] memory) {
        return _queens; 
    }

    function getOpenRewardStatus() external view returns(bool) {
        return _openRewards; 
    }

    function getTotalRewards(address queen) external view onlyOwner returns(uint96) {
        return _totalRewardsEarned[queen]; 
    }
}