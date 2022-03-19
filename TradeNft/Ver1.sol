// SPDX-License-Identifier: MIT
pragma solidity 0.8;

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// an example for listing to sell
contract NFTtrade is Ownable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;

    IERC721 public erc721;
    
    struct List{
        uint256 price;
        address seller;
    }
    mapping(address => mapping(uint256 => List)) listing;

    mapping(address => uint256) public balance; // erc20 balance after sell :)

    // events [not indexed design]
    event ListingNft(address nft, uint256 id, address owner, uint256 price, uint256 date);
    event BuyNft(address nft, uint256 id, address collector, uint256 price, uint256 date);
    event Witdraw(uint256 date, uint256 cash);
    event Deposit(address who, uint256 price, uint256 date);

    // list an nft
    function addListing(address nft, uint256 price, uint256 id) public onlyOwner {
        erc721 = IERC721(nft);
        // require = owner of, isApprovedFoAll
        listing[address(erc721)][id] = List(price, msg.sender);
        emit ListingNft(nft, id, msg.sender, price, block.timestamp);
    }

    // purchase/buy nft
    function buyNFT(address nft, uint256 id) public payable {
        List memory item = listing[nft][id];
        require(msg.value >= item.price);
        // require id isExistedListing
        balance[item.seller] += msg.value;
        erc721 = IERC721(nft);
        erc721.transferFrom(item.seller, msg.sender, id);
        emit BuyNft(nft, id, msg.sender, item.price, block.timestamp);
    }

    // intract by erc721 contracts 
    function onERC721Received(
        address, address, uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // cash out
    function withdraw() public onlyOwner nonReentrant { 
        uint256 cash = balanceOf();
        (bool success, ) = msg.sender.call{value: balanceOf()}("");
		require(success);
        emit Witdraw(block.timestamp, cash);
    }

    function balanceOf() view public returns(uint) {
        return address(this).balance;
    }

    // lowlevel deposit methods
    receive() external payable{
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }

    fallback() external payable{
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
}

// after mint, approveAll NftWallet smartcontract address
contract NftTest is ERC721 {
    uint id = 1;
    constructor() ERC721("test","TST"){
        _mint(msg.sender, id);
        id += 1;
    }
    
    function mint() external{
        _mint(msg.sender, id);
        id += 1;
    }
}
