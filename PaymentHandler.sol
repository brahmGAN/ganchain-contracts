// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PaymentHandler is Ownable, ReentrancyGuard {
    address public usdcTokenAddress;
    address public usdtTokenAddress;
    address[] USDCpayers;
    address[] USDTpayers;
    
    mapping(address => mapping (address => uint256)) public tokenPayer;

    // Events
    event TokenReceived(address indexed _sender, uint256 _amount, address indexed _tokenAddress);
    event WithdrawToken(address indexed _owner, address indexed _tokenAddress, address indexed _receiver, uint256 _value);

    constructor(address initialOwner, address _usdcTokenAddress, address _usdtTokenAddress) Ownable(initialOwner) {
        require(initialOwner != address(0), "Invalid initial owner address");
        require(_usdcTokenAddress != address(0), "Invalid usdc token address");
        require(_usdtTokenAddress != address(0), "Invalid usdt token address");
        usdcTokenAddress = _usdcTokenAddress;
        usdtTokenAddress = _usdtTokenAddress;
    }
    
    function onTokenTransferUSDC(uint256 _amount) public {
        require(ERC20(usdcTokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient token");
        require(ERC20(usdcTokenAddress).allowance(msg.sender,address(this)) >= _amount,"Not approved");
        ERC20(usdcTokenAddress).transferFrom(msg.sender, address(this), _amount);
        USDCpayers.push(msg.sender);
        tokenPayer[msg.sender][usdcTokenAddress] += _amount;
        emit TokenReceived(msg.sender,_amount,usdcTokenAddress);
    }

    function onTokenTransferUSDT(uint256 _amount) public {
        require(ERC20(usdtTokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(ERC20(usdtTokenAddress).allowance(msg.sender,address(this)) >= _amount,"Not approved");
        ERC20(usdtTokenAddress).transferFrom(msg.sender, address(this), _amount);
        USDTpayers.push(msg.sender);
        tokenPayer[msg.sender][usdtTokenAddress] += _amount;
        emit TokenReceived(msg.sender,_amount,usdtTokenAddress);
    }
    
    function withdrawUSDCToken(address _to, uint256 _amount) external nonReentrant onlyOwner {
        uint token = getContractUSDCTokenBalance();
        require( token >= _amount,"Insufficient token balance");
        ERC20(usdcTokenAddress).transfer(_to, _amount);
        emit WithdrawToken(msg.sender, usdcTokenAddress, _to, _amount);
    }

    function withdrawUSDTToken(address _to, uint256 _amount) external nonReentrant onlyOwner {
        uint token = getContractUSDTTokenBalance();
        require( token >= _amount,"Insufficient token balance");
        ERC20(usdtTokenAddress).transfer(_to, _amount);
        emit WithdrawToken(msg.sender, usdtTokenAddress, _to, _amount);
    }

    //getter functions
    function getContractUSDCTokenBalance() public view returns (uint) {
         return ERC20(usdcTokenAddress).balanceOf(address(this));
    }

    function getContractUSDTTokenBalance() public view returns (uint) {
         return ERC20(usdtTokenAddress).balanceOf(address(this));
    }

    function getUSDCpayers() public view returns (address[] memory){
        return USDCpayers;
    }

    function getUSDTpayers() public view returns (address[] memory){
        return USDTpayers;
    }
}