// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "./IERC721.sol";
import "./Ownable.sol";

contract KittyContract is IERC721, Ownable{

    string public constant name = "ZKitties";
    string public constant symbol = "ZK";
    uint public constant LIMIT_GEN0 = 10;

    struct Kitty{
        uint256 genes;
        uint64 birthTime;
        uint32 mumId;
        uint32 dadId;
        uint16 generation;
    }

    Kitty[] kitties;

    mapping (address => uint) balances;
    mapping (uint => address) public tokenOwner;
    mapping (uint => address) public tokenApprovedTo;
    mapping (address => mapping (address => bool)) private operatorApprovals;

    uint256 public gen0Counter;

    event Birth(address owner, uint kittyId, uint genes, uint mumId, uint dadId);

    function approve(address _approved, uint256 _tokenId) external {
        require(_owns(msg.sender, _tokenId));
        _approve(_approved, _tokenId);

        emit Approval(msg.sender, _approved,_tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external{
        require(msg.sender != _operator);
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address){
        require(_tokenId < kitties.length);
        return tokenApprovedTo[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool){
        return operatorApprovals[_owner][_operator];
    }

    function _approve(address _approved, uint256 _tokenId) internal {
        tokenApprovedTo[_tokenId] = _approved;
    }

    function createKittyGen0(uint _genes) public onlyOwner{
        require(gen0Counter < LIMIT_GEN0);
        _createKitty(_genes, 0, 0, 0, msg.sender);
        gen0Counter++;
    }

    function getKitty(uint _id) external view returns(
        uint256 genes,
        uint256 birthTime,
        uint256 mumId,
        uint256 dadId,
        uint256 generation
    ){
            Kitty memory kitty = kitties[_id];
            genes = uint256(kitty.genes);
            birthTime = uint256(kitty.birthTime);
            mumId = uint256(kitty.mumId);
            dadId = uint256(kitty.dadId);
            generation = uint256(kitty.generation);
        }

    function _createKitty(
        uint256 _genes,
        uint32 _mumId,
        uint32 _dadId,
        uint16 _generation,
        address _owner
    ) internal returns(uint256){
        Kitty memory kitty = Kitty(
            _genes,
            uint64(block.timestamp),
            uint32(_mumId),
            uint32(_dadId),
            _generation
        );
        kitties.push(kitty);
        uint kittyId = kitties.length - 1;
        _transfer(address(0), _owner, kittyId);
        emit Birth(_owner, kittyId, _genes, _mumId, _dadId);
        return kittyId;
    }

    function balanceOf(address owner) external view returns (uint256){
        return balances[owner];
    }

    function totalSupply() external view returns (uint256){
        return kitties.length;
    }

    function ownerOf(uint256 tokenId) external view returns (address){
        return tokenOwner[tokenId];
    }

    function transfer(address to, uint256 tokenId) external{
        require(to != address(0));
        require(to != address(this));
        require(_owns(msg.sender, tokenId));
        _transfer(msg.sender, to, tokenId);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal{
        balances[_to]++;
        tokenOwner[_tokenId] = _to;
        if(_from != address(0)){
            balances[_from]--;
            delete tokenApprovedTo[_tokenId];
        }
        emit Transfer(_from, _to, _tokenId);
    }

    function _owns(address _owner, uint256 _tokenId) internal view returns (bool) {
        return tokenOwner[_tokenId] == _owner;
    }

}



