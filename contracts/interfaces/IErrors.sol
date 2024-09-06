// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Errors only interface for the {GPU} implementations.
 */
interface IErrors {
  /**
   * @dev Displayed when the user doesn't have a Node NFT key.  
   */
  error GetNodeNFT();

  /**
   * @dev Displayed when it's not been 24 hours since last call. 
   */
  error InComplete24Hours();

  /**
   * @dev Displayed when the `msg.value` doesn't match the swap request.
   */
  error InsufficientStake();
}