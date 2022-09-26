// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Kitty.sol";
import "./Ownable.sol";
import "./IKittyMarketplace.sol";

contract KittyMarketPlace is Ownable, IKittyMarketPlace {
    KittyContract private _kittyContract;

    struct Offer {
        address payable seller;
        uint256 price;
        uint256 index;
        uint256 tokenId;
        bool active;
    }

    Offer[] offers;

    mapping(uint256 => Offer) tokenIdToOffer;

    function setKittyContract(address _kittyContractAddress) external onlyOwner{
        _kittyContract = KittyContract(_kittyContractAddress);
    }

    function getOffer(uint256 _tokenId) external view returns ( address seller, uint256 price, uint256 index, uint256 tokenId, bool active){
        Offer memory _offer = tokenIdToOffer[_tokenId];
        return(
            _offer.seller,
            _offer.price,
            _offer.index,
            _offer.tokenId,
            _offer.active
        );
        
    }

    function getAllTokenOnSale() external view returns(uint256[] memory){
       uint counter = 0;
       Offer[] memory _offers = offers;
        uint totalOffers = _offers.length;
       if(totalOffers == 0){
            return new uint[](0);
       }else{
            uint[] memory listOfOffers = new uint[](totalOffers);
            for(uint i = 0; i < totalOffers; i++){
                if(_offers[i].active){
                    listOfOffers[counter] = _offers[i].tokenId;
                    counter++;
                }
            }
            return listOfOffers;
       }
       
    }


    function setOffer(uint256 _price, uint256 _tokenId) external{
        _isTokenOwner(_tokenId);
        require(tokenIdToOffer[_tokenId].active == false, "there is already an offer active for this token");
        require(_kittyContract.isApprovedForAll(msg.sender, address(this)), "Contract need to be approved");      
        Offer memory newOffer = Offer(payable(msg.sender), _price, offers.length, _tokenId, true);
        tokenIdToOffer[_tokenId] = newOffer;
        offers.push(newOffer);
        emit MarketTransaction("Create offer", msg.sender, _tokenId);
    }

    function removeOffer(uint256 _tokenId) public{
        _isTokenOwner(_tokenId);
        offers[tokenIdToOffer[_tokenId].index] = offers[offers.length - 1];
        offers.pop();
        delete tokenIdToOffer[_tokenId];     
        emit MarketTransaction("Remove offer", msg.sender, _tokenId);
    }

    function buyKitty(uint256 _tokenId) external payable{
        Offer memory _offer = tokenIdToOffer[_tokenId];
        require(msg.value == _offer.price, "wrong amount!");
        require(_offer.active, "the offer should be active!");
        offers[tokenIdToOffer[_tokenId].index].active = false;
        delete tokenIdToOffer[_tokenId];  
        _kittyContract.transferFrom(address(this), _offer.seller, _tokenId);
        if(_offer.price > 0){
            _offer.seller.transfer(msg.value);
        }
        emit MarketTransaction("Buy", msg.sender, _tokenId);
    }

    function _isTokenOwner(uint _tokenId) internal view {
        address _tokenOwner = _kittyContract.ownerOf(_tokenId);
        require(_tokenOwner == msg.sender, "Only for token owner");
    }

}