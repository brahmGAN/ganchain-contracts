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

    mapping(address => PaymentInfo) public H160Info;
    mapping(string => PaymentInfo) public SS58Info;
    mapping(address => string[]) public ss58Address;
    address[] tokenPayers;

    // Events
    event USDCReceivedForH160(address indexed _sender, uint _amount, uint timestamp);
    event USDCReceivedForSS58(address indexed _sender,string ss58Address, uint _amount, uint timestamp);
    event USDTReceivedForH160(address indexed _sender, uint _amount, uint timestamp);
    event USDTReceivedForSS58(address indexed _sender,string ss58Address, uint _amount, uint timestamp); 
    event WithdrawToken(address indexed _owner, address indexed _tokenAddress, address indexed _receiver, uint256 _value);

    constructor(address initialOwner, address _usdcTokenAddress, address _usdtTokenAddress, address _fundsHandler) Ownable(initialOwner) {
        require(initialOwner != address(0), "Invalid initial owner address");
        require(_usdcTokenAddress != address(0), "Invalid usdc token address");
        require(_usdtTokenAddress != address(0), "Invalid usdt token address");
        require(_fundsHandler != address(0), "Invalid funds handler address");
        usdcTokenAddress = _usdcTokenAddress;
        usdtTokenAddress = _usdtTokenAddress;
        fundsHandler = _fundsHandler;
    }
    
    function usdcTransferH160(uint256 _amount) external {
        require(IERC20(usdcTokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient token");
        require(IERC20(usdcTokenAddress).allowance(msg.sender, address(this)) >= _amount,"Not approved");
        IERC20(usdcTokenAddress).safeTransferFrom(msg.sender, fundsHandler, _amount);
        if(!H160Info[msg.sender].exists){
            tokenPayers.push(msg.sender);
            H160Info[msg.sender].exists = true;
        }
        H160Info[msg.sender].usdcAmount += _amount;
        emit USDCReceivedForH160(msg.sender,_amount, block.timestamp);
    }

    function usdtTransferH160(uint256 _amount) external {
        require(IERC20(usdtTokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient token");
        require(IERC20(usdtTokenAddress).allowance(msg.sender, address(this)) >= _amount,"Not approved");
        IERC20(usdtTokenAddress).safeTransferFrom(msg.sender, fundsHandler, _amount);
        if(!H160Info[msg.sender].exists){
            tokenPayers.push(msg.sender);
            H160Info[msg.sender].exists = true;
        }
        H160Info[msg.sender].usdtAmount += _amount;
        emit USDTReceivedForH160(msg.sender,_amount, block.timestamp);
    }

    function usdcTransferSS58(uint256 _amount, string calldata _ss58Address) external {
        require(IERC20(usdcTokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(IERC20(usdcTokenAddress).allowance(msg.sender, address(this)) >= _amount,"Not approved");
        require(bytes(_ss58Address).length == 48, "Invalid SS58 address");
        IERC20(usdcTokenAddress).safeTransferFrom(msg.sender, fundsHandler, _amount);
        if(!SS58Info[_ss58Address].exists){
            ss58Address[msg.sender].push(_ss58Address);
            SS58Info[_ss58Address].exists = true; 
        }
        if(!H160Info[msg.sender].exists){
            tokenPayers.push(msg.sender);
            H160Info[msg.sender].exists = true;
        }
        SS58Info[_ss58Address].usdcAmount += _amount;
        emit USDCReceivedForSS58(msg.sender,_ss58Address, _amount, block.timestamp);
    }

    function usdtTransferSS58(uint256 _amount, string calldata _ss58Address) external {
        require(IERC20(usdtTokenAddress).balanceOf(msg.sender) >= _amount, "Insufficient token balance");
        require(IERC20(usdtTokenAddress).allowance(msg.sender, address(this)) >= _amount,"Not approved");
        require(bytes(_ss58Address).length == 48, "Invalid SS58 address");
        IERC20(usdtTokenAddress).safeTransferFrom(msg.sender, fundsHandler, _amount);
        if(!SS58Info[_ss58Address].exists){
            SS58Info[_ss58Address].exists = true;   
        }
        if(!H160Info[msg.sender].exists){
            tokenPayers.push(msg.sender);
            H160Info[msg.sender].exists = true;
        }
        SS58Info[_ss58Address].usdtAmount += _amount;
        emit USDTReceivedForSS58(msg.sender,_ss58Address, _amount, block.timestamp);
    }


    //getter functions
    function getSS58Addresses(address _payer)public view returns(string[] memory){
        return ss58Address[_payer];
    }

    function getPayers() public view  returns(address[] memory){
        return tokenPayers;
    }

    //setter functions
    function setFundsHandler(address _fundsHandler) external onlyOwner {
        require(_fundsHandler != address(0), "Invalid funds handler address");
        fundsHandler = _fundsHandler;
    }
}