// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC721.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SwapContract {

    struct Listing {
        address seller;
        uint256 price;
    }

    // Mapping from token contract address to token ID to Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed(address indexed tokenContract, uint256 indexed tokenId, address indexed seller, uint256 price);
    event Unlisted(address indexed tokenContract, uint256 indexed tokenId);
    event Purchased(address indexed tokenContract, uint256 indexed tokenId, address indexed buyer, address seller, uint256 price);

    // List an ERC721 token for sale
    function listToken(address tokenContract, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        require(IERC721(tokenContract).ownerOf(tokenId) == msg.sender, "You do not own this token");
        require(listings[tokenContract][tokenId].seller == address(0), "Token already listed");

        // Transfer the token to the marketplace
        IERC721(tokenContract).transferFrom(msg.sender, address(this), tokenId);

        listings[tokenContract][tokenId] = Listing(msg.sender, price);
        emit Listed(tokenContract, tokenId, msg.sender, price);
    }

    // Buy an ERC721 token
    function buyToken(address tokenContract, uint256 tokenId) external payable {
        Listing memory listing = listings[tokenContract][tokenId];
        require(listing.seller != address(0), "Token not listed");
        require(msg.value >= listing.price, "Insufficient funds sent");

        // Transfer the token to the buyer
        IERC721(tokenContract).transferFrom(address(this), msg.sender, tokenId);
        // Transfer the funds to the seller
        payable(listing.seller).transfer(listing.price);

        // Remove listing
        delete listings[tokenContract][tokenId];
        emit Purchased(tokenContract, tokenId, msg.sender, listing.seller, listing.price);
    }

    // Unlist an ERC721 token
    function unlistToken(address tokenContract, uint256 tokenId) external {
        Listing memory listing = listings[tokenContract][tokenId];
        require(listing.seller == msg.sender, "Only the seller can unlist");

        // Transfer the token back to the seller
        IERC721(tokenContract).transferFrom(address(this), msg.sender, tokenId);
        
        // Remove listing
        delete listings[tokenContract][tokenId];
        emit Unlisted(tokenContract, tokenId);
    }
}
