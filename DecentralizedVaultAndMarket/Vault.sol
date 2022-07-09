// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        returns(bytes4);
}

interface INftVault is IERC165, ERC721TokenReceiver {
    event RecieveNFT(uint id, address indexed actor, uint time);
    event ListNFT(uint id, address indexed actor, uint indexed price, uint time);
    event SellNFT(uint id, address indexed actor, uint indexed price, uint time);

    function reciveNft(address _nft, uint _id) external returns (bool result);
    function listNft(uint price) external returns (bool result);
    function listNftById(uint _itemId, uint price) external returns (bool result);
    function buy(uint _id, uint _listId, uint _price) payable external returns (bool result);
    function unHold(address _nft, uint _id, address _recipient) external returns (bool result);
    
}

contract NftVault is INftVault, ERC165 {
    using Address for address;
    using Counters for Counters.Counter;

    Counters.Counter private itemsID; // .current() .increment() .decrement() .reset()
    struct Item {
        bool isListed;
        uint itemId;
        uint price;
        uint nftId;
        address nft; 
        address owner;
    }
    mapping(uint => Item) private items; // itemsID -> fetch/parse Item
    mapping(address => mapping(uint => bool)) private validUser; // security check

    // errors ----------------------------------
    // have  var 
    error CustomeError1(uint fee, uint balance);
    // haven`t  var 
    error CustomeError2();
    /// can not find item by this information for transfering
    error errorUnHold();

    // init ----------------------------------
    constructor() {
        // itemsID.increment();
    }

    receive() external payable {}

    
    // modifiers ----------------------------------
    modifier listValidation(uint _id) {
        _listValidation(_id);
        _;
    }

    function _listValidation(uint _id) private view {
        require(validUser[_msgSender()][_id] ==true, "not valid user");
        require(items[_id].isListed == false, "deal is deal, this item listed to sell");
    }

    // calculation ----------------------------------
    function _reciveNft(address _nft, uint _id) internal returns (bool result) {
        IERC721(_nft).transferFrom(msg.sender, _this(), _id);
        result = true;
    }

    function reciveNft(address _nft, uint _id) external virtual override returns (bool result){
        require(_isOwner(_nft, _id), "only nft owner is valid");
        itemsID.increment();
        uint id = itemsID.current();
        // approve for all for this address by using signature in frontend
        require(_reciveNft(_nft, _id), "transfer failed");
        items[id] = Item(false, id, 0, _id, _nft, _msgSender()); // create
        validUser[_msgSender()][id] = true;
        require(_checkOnERC721Received(_msgSender(), _this(), _id, _msgData()), "transfer to non ERC721Receiver implementer");
        emit RecieveNFT(_id, _msgSender(), block.timestamp);
        result = true;
    }

    function _listNft(uint _id, uint _price) internal virtual listValidation(_id) returns (bool result) {
        // require(validUser[_msgSender()][_id] ==true, "not valid user");
        // require(items[_id].isListed == false, "deal is deal, this item listed to sell");
        items[_id].isListed = true;
        items[_id].price = _price;
        result = true;
    }

    function listNft(uint price) external virtual override returns (bool result){
        uint id = findId();
        result = _listNft(id, price);
        emit ListNFT(id, _msgSender(), price, block.timestamp);
        // require(_listNft(id, price), "can not listing");
        // result = true;
    }

    function listNftById(uint _itemId, uint price) external virtual override returns (bool result){
        result = _listNft(_itemId, price);
        emit  ListNFT(_itemId, _msgSender(), price, block.timestamp);
        // require(_listNft(_itemId, price), "can not listing");
        // result = true;
    }

    function buy(uint _id, uint _listId, uint _price) payable external virtual override returns (bool result){

    }
    
    function unHold(address _nft, uint _id, address _recipient) external virtual override returns (bool result){
        uint j = itemsID.current();
        result = false;
        for(uint i=0; i <= j; i++){
            if(items[i].owner == _msgSender()){
                require(items[i].isListed == false, "deal is deal, this item listed to sell");
                IERC721(_nft).transferFrom(address(this), _recipient, _id);
                IERC721(_nft).setApprovalForAll(_recipient, true);
                validUser[_msgSender()][i] = false;
                items[i] = Item(false, i, 0, 0, address(0), address(0));
            }
            result = true;
        }
    }

    function findUser() public view returns (address user) {
        uint j = itemsID.current();
        user = address(0);
        for(uint i=0; i <= j; i++){
            if(items[i].owner == _msgSender()){
                user = _msgSender();
            }
        }
    }
    
    function findId() public view returns (uint id) {
        uint j = itemsID.current();
        id = 0;
        for(uint i=0; i <= j; i++){
            if(items[i].owner == _msgSender()){
                id = items[i].itemId;
            }
        }
    }

    // helpers ----------------------------------
    function _items(uint id) public view returns (Item memory) {
        return items[id];
    }
    
    function _isOwner(address _nft, uint _id) internal view virtual returns (bool) {
        require(_exist(_nft, _id), "nonexistent token");
        if(IERC721(_nft).ownerOf(_id) == _msgSender()) {
            return true;
        }
        else {
            return false;
        }
    }

    function _isApprovedOrOwner(address _nft, address spender, uint256 _id) internal view virtual returns (bool) {
        require(_exist(_nft, _id), "nonexistent token");
        address owner = IERC721(_nft).ownerOf(_id);
        // return (spender == owner || _before(_nft, _id));
        return (spender == owner);
    }

    function _exist(address _nft, uint _id) internal view virtual returns (bool) {
        return IERC721(_nft).ownerOf(_id) != address(0);
    }


    // validators ----------------------------------
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(INftVault).interfaceId || 
        interfaceId == type(IERC721).interfaceId || 
        interfaceId == type(ERC721TokenReceiver).interfaceId || 
        interfaceId == type(IERC721Receiver).interfaceId || 
        super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address ,
        address ,
        uint256 ,
        bytes calldata 
    )
    external override pure
    returns(bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 
    // IERC721Receiver.onERC721Received.selector
    // IERC721.onERC721Received.selector

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    } // require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");

    // libs ----------------------------------
    function _this() internal view virtual returns (address) {
        return address(this);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }


}





// function _safeTransfer(
//     address token, 
//     address to, 
//     uint value
// ) private {        
    
//     (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
    
//     require(
//         success && (data.length == 0 || abi.decode(data, (bool))),
//         'UniswapV2: TRANSFER_FAILED');    
// }

// bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
