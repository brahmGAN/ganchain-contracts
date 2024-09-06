// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Errors only interface for the {GPU} implementations.
 */
interface IErrors {
  /**
   * @dev Displayed when the user doesn't have a Node NFT key.  
   */
  error BuyNodeNFT();

  /**
   * @dev Displayed when it's not been 24 hours since last call. 
   */
  error InComplete24Hours();

  /**
   * @dev Displayed when the staking amount is less than the minimum required, which is 1000 GPoints. 
   */
  error InsufficientStakes();

  /**
   * @dev Displayed when there are no rewards to claim
   */
  error NoRewards();

  /**
   * @dev Displayed when transfer failed 
   */
  error TransferFailed();
}