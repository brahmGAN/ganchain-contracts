// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PaymentHandler is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public usdcTokenAddress;
    address public usdtTokenAddress;
    address public fundsHandler;
    
    struct PaymentInfo{
        uint usdcAmount;
        uint usdtAmount;
        bool exists;
    }

    mapping(address => PaymentInfo) public paymentInfo;
    address[] tokenPayers;

    // Events
    event USDCReceived(address indexed _sender, uint _amount, uint timestamp);
    event USDTReceived(address indexed _sender, uint _amount, uint timestamp);

    constructor(address initialOwner, address _usdcTokenAddress, address _usdtTokenAddress, address _fundsHandler) Ownable(initialOwner) {
        require(initialOwner != address(0), "Invalid initial owner address");
        require(_usdcTokenAddress != address(0), "Invalid usdc token address");
        require(_usdtTokenAddress != address(0), "Invalid usdt token address");
        require(_fundsHandler != address(0), "Invalid funds handler address");
        usdcTokenAddress = _usdcTokenAddress;
        usdtTokenAddress = _usdtTokenAddress;
        fundsHandler = _fundsHandler;
    }
    
    function usdcTransfer(uint256 _amount) external {
        require(IERC20(usdcTokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient token");
        require(IERC20(usdcTokenAddress).allowance(msg.sender,fundsHandler) >= _amount,"Not approved");
        IERC20(usdcTokenAddress).safeTransferFrom(msg.sender, fundsHandler, _amount);
        if(!paymentInfo[msg.sender].exists){
            tokenPayers.push(msg.sender);
            paymentInfo[msg.sender].exists = true;
        }
        paymentInfo[msg.sender].usdcAmount += _amount;
        emit USDCReceived(msg.sender,_amount, block.timestamp);
    }

    function usdtTransfer(uint256 _amount) external {
        require(IERC20(usdtTokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient token");
        require(IERC20(usdtTokenAddress).allowance(msg.sender, fundsHandler) >= _amount,"Not approved");
        IERC20(usdtTokenAddress).safeTransferFrom(msg.sender, fundsHandler, _amount);
        if(!paymentInfo[msg.sender].exists){
            tokenPayers.push(msg.sender);
            paymentInfo[msg.sender].exists = true;
        }
        paymentInfo[msg.sender].usdtAmount += _amount;
        emit USDTReceived(msg.sender,_amount, block.timestamp);
    }

    //getter functions

    function getPayers() public view  returns(address[] memory){
        return tokenPayers;
    }

    //setter functions
    function setFundsHandler(address _fundsHandler) external onlyOwner {
        require(_fundsHandler != address(0), "Invalid funds handler address");
        fundsHandler = _fundsHandler;
    }
}