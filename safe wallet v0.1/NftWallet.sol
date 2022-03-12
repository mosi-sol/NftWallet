// SPDX-License-Identifier: MIT
pragma solidity 0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// need: checker, conditions, require reverts
// check exist id, approved id,etc...

contract NftWallet{
    mapping(uint256 => address) public owner; // sender=>covrage
    uint256 covrage; // saved item id (a db), seprate owners

    function receiveNft(ERC721 _nft, uint id) external{
        _nft.transferFrom(msg.sender, address(this), id);
        owner[covrage] = msg.sender;
        covrage += 1;
    }
    
    function sendNft(ERC721 nft, address spender, uint id) external{
        // require(check owner)
        require(spender != address(0), "i hate to burn nft`s");
        nft.transferFrom(address(this), spender, id);
        owner[covrage] = address(0); // need to edit, problem here or check console maybe work
    }
}

// after mint, approve NftWallet smartcontract address
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
