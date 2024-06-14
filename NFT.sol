// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract NewNFT is ERC721, Ownable {
    event isminted(address to);
    constructor() ERC721("NewNFT", "NEW")  Ownable(msg.sender){
    }
    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
        emit isminted(to);
    }
}