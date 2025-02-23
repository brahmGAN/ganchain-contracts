// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IQueenStake {
    event staked(
        address queen, 
        uint88 currentStakedAmount
    );
    event newstaked(
        address queen, 
        uint88 currentStakedAmount, 
        uint88 totalUserStakedAmount, 
        uint88 unUsedStakedAmount, 
        uint96 totalStakes 
    );
    event claimedRewards(
        address queen, 
        uint96 rewardsClaimed
    );
    event accumulatedDailyQueenRewards(
        uint40 lastRewardCalculated
    );
    event unStaked(
        address queen, 
        uint88 amount
    );
    event validatorEnrolled(
        address validator 
    );
    event authorizedUnStaked(
        address queen, 
        uint96 amount
    );
    function stake() external payable;
    function accumulateDailyQueenRewards() external;
    function unStake(uint88 amount) external; 
}