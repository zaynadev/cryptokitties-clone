// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";

contract KittyContract is IERC721, Ownable{

    string public constant name = "ZKitties";
    string public constant symbol = "ZK";
    uint public constant LIMIT_GEN0 = 10;
    bytes4 internal constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('supportsInterface(bytes4)'));
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

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

    function supportsInterface(bytes4 _interfaceId) external pure returns (bool){
        return ( _interfaceId == _INTERFACE_ID_ERC721 || _interfaceId == _INTERFACE_ID_ERC165);
    }

    function breed(uint256 _dadId, uint256 _mumId) public returns (uint256){
        require(_owns(msg.sender, _dadId), "The user doesn't own the token");
        require(_owns(msg.sender, _mumId), "The user doesn't own the token");

        ( uint256 dadDna,,,,uint256 DadGeneration ) = getKitty(_dadId);

        ( uint256 mumDna,,,,uint256 MumGeneration ) = getKitty(_mumId);
        
        uint256 newDna = _mixDna(dadDna, mumDna);

        uint256 kidGen = 0;
        if (DadGeneration < MumGeneration){
            kidGen = MumGeneration + 1;
            kidGen /= 2;
        } else if (DadGeneration > MumGeneration){
            kidGen = DadGeneration + 1;
            kidGen /= 2;
        } else{
            kidGen = MumGeneration + 1;
        }

        _createKitty(_mumId, _dadId, kidGen, newDna, msg.sender);

        return newDna;
    }
    

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

    function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address){
        return tokenApprovedTo[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool){
        return operatorApprovals[_owner][_operator];
    }


    function createKittyGen0(uint _genes) public onlyOwner{
        require(gen0Counter < LIMIT_GEN0);
        _createKitty(_genes, 0, 0, 0, msg.sender);
        gen0Counter++;
    }

    function getKitty(uint _id) public view returns(
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

    function getKittyByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](balances[_owner]);
        uint counter = 0;
        for (uint i = 0; i < kitties.length; i++) {
            if (tokenOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
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

    function transfer(address to, uint256 tokenId) external isValidAddress(to){
        require(to != address(this));
        require(_owns(msg.sender, tokenId));
        _transfer(msg.sender, to, tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external isValidAddress(_to) onlyOwner isValidToken(_tokenId){
        require(_from == msg.sender || _approvedFor(_tokenId,_from) || operatorApprovals[_from][msg.sender]);
        _transfer(msg.sender, _to, _tokenId);
    }

    modifier isValidAddress(address _address){
        require(_address != address(0));
        _;
    }

    modifier isValidToken(uint _tokenId){
        require(_tokenId < kitties.length);
        _;
    }

    function _createKitty(
        uint256 _genes,
        uint256 _mumId,
        uint256 _dadId,
        uint256 _generation,
        address _owner
    ) internal returns(uint256){
        Kitty memory kitty = Kitty(
            _genes,
            uint64(block.timestamp),
            uint32(_mumId),
            uint32(_dadId),
            uint16(_generation)
        );
        kitties.push(kitty);
        uint kittyId = kitties.length - 1;
        _transfer(address(0), _owner, kittyId);
        emit Birth(_owner, kittyId, _genes, _mumId, _dadId);
        return kittyId;
    }

   function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        require( _isApprovedOrOwner(msg.sender, _from, _to, _tokenId) );
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory _data) internal{
        _transfer(_from, _to, _tokenId);
        require( _checkERC721Support(_from, _to, _tokenId, _data) );
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

    function _approve(address _approved, uint256 _tokenId) internal {
        tokenApprovedTo[_tokenId] = _approved;
    }

    function _approvedFor(uint _tokenId, address _approvedTo) internal view returns(bool){
        return tokenApprovedTo[_tokenId] == _approvedTo;
    }

    function _checkERC721Support(address _from, address _to, uint _tokenId, bytes memory data) internal returns (bool){
        if(!_isContract(_to)){
            return true;
        }

        bytes4 returnData = IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, data);
        return returnData == ERC721_RECEIVED;
    }

    function _isContract(address _to) internal view returns (bool){
        uint32 size;
        assembly{
            size := extcodesize(_to)
        }
        return size > 0;
    }

    function _isApprovedOrOwner(address _spender, address _from, address _to, uint256 _tokenId) internal view isValidAddress(_to) isValidToken(_tokenId) returns (bool) {
        require(_owns(_from, _tokenId)); 
        
        return (_spender == _from || _approvedFor(_tokenId, _from) || isApprovedForAll(_from, _spender));
    }

    function _mixDna(uint256 _dadDna, uint256 _mumDna) internal pure returns (uint256){
        //dadDna: 11 22 33 44 55 66 77 88 
        //mumDna: 88 77 66 55 44 33 22 11

        uint256 firstHalf = _dadDna / 100000000; //11223344
        uint256 secondHalf = _mumDna % 100000000; //88776655
        
        uint256 newDna = firstHalf * 100000000;
        newDna = newDna + secondHalf; // 1122334488776655
        return newDna;

        //11 22 33 44 88 77 66 55

        //10 + 20
        //10 * 100 = 1000
        //1000 + 20 = 1020
    
    }
}



