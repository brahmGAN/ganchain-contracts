// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IQueenStake {
    event staked(
        address queen, 
        uint88 currentStakedAmount
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
        uint192 amount
    );
    event skippedQueens(
        uint96 skipped
    );
    event createdSubnet(
        uint88 subnetId,
        address subnetKing 

    );
    event deletedSubnet(
        uint88 subnetId,
        address subnetKing 
    );

    event accumulatedDailyKingRewards(
        uint96 skippedKings
    );
    function stake() external payable;
    // function accumulateDailyQueenRewards() external;
    function unStake(uint88 amount) external; 
}