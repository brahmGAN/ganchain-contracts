// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IERC721 {
    function balanceOf(address nftOwner) external view returns (uint256);
}