// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDT
 * @dev Mock USDT token for testing (6 decimals like real USDT)
 */
contract MockUSDT is ERC20, Ownable {
    uint8 private _decimals;

    constructor(address initialOwner) ERC20("Mock USDT", "USDT") Ownable(initialOwner) {  // ← FIXED
        _decimals = 6; // USDT uses 6 decimals
        _mint(initialOwner, 1000000 * 10**_decimals); // Mint 1M USDT to owner
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Faucet for easy testing
    function faucet(uint256 amount) external {
        require(amount <= 10000 * 10**_decimals, "MockUSDT: Max 10,000 USDT per request");
        _mint(msg.sender, amount);
    }
}

/**
 * @title MockGPU
 * @dev Mock GPU token for testing (18 decimals - standard)
 */
contract MockGPU is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Mock GPU Token", "GPU") Ownable(initialOwner) {  // ← FIXED
        _mint(initialOwner, 1000000 * 10**18); // Mint 1M GPU tokens to owner
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Faucet for easy testing
    function faucet(uint256 amount) external {
        require(amount <= 1000 * 10**18, "MockGPU: Max 1,000 GPU per request");
        _mint(msg.sender, amount);
    }
}