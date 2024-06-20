// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact info@brahmgan.com
contract GANNode is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    
    uint public maxTokenId;
    uint public constant MAX_SUPPLY = 15000; //Change it to set the value using a new function
    string public URI; //Will change to the ipfs hash
    mapping (address => uint) public userMinted;

    constructor(address initialOwner)
        ERC721("GAN-Node", "GN")
        Ownable(initialOwner)
    {}

    event minted(address indexed minter, uint quantity);
    
    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function safeMint(address to, uint mintQuantity) public onlyOwner {
        require(maxTokenId < MAX_SUPPLY, "We are sold out :(");
        
        for (uint i=1; i<= mintQuantity; i++) {
            maxTokenId+=1;
            _safeMint(to, maxTokenId);
            _setTokenURI(maxTokenId, URI);
        }
        userMinted[to] += mintQuantity;
        emit minted(to, mintQuantity);
    }

    function batchMinting(address[] memory toMint, uint[] memory quantity) public onlyOwner {
        require(toMint.length == quantity.length, "Invalid data");
        for(uint i=0; i< toMint.length; i++) {
            safeMint(toMint[i], quantity[i]);
        }
    }

    function privateSale(address toSend, uint amount) public onlyOwner {
        require((amount + maxTokenId) <= MAX_SUPPLY );
        safeMint(toSend, amount);
    }

    function setURI(string memory newURI) public onlyOwner {
        URI = newURI;
    }

    // The following functions are overrides required by Solidity.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public  virtual override(ERC721, IERC721) { 
        require(from == address(0), "Soulbound tokens cannot be transferred.");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) {
        require(from == address(0), "Soulbound tokens cannot be transferred.");
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}