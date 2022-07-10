// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// NFT MOCK
/* -------------------------------------------- */
// after mint, approve NftWallet smartcontract address
contract NftMock is ERC721 {
    uint id = 0;
    constructor() ERC721("mock nft","MOK"){
        _mint(msg.sender, id);
        id += 1;
    }
    
    function mint() external{
        _mint(msg.sender, id);
        id += 1;
    }
}
