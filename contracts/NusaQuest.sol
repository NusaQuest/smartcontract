// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC1155URIStorage} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NusaQuest is
    ERC1155URIStorage,
    ERC1155Holder,
    Ownable,
    ReentrancyGuard
{
    //
    struct Proof {
        string destinationId;
        address user;
        uint256 timestamp;
        string[] proofs;
    }
    Proof[] private proofs;
    mapping(string => mapping(address => uint256)) private lastClaims;
    mapping(uint256 => uint256) private prices;
    uint256 private constant FUNGIBLE_TOKEN_ID = 0;
    uint256 private constant CLAIM_LIMIT_PER_DAY_PER_DESTINATION = 20;
    uint256 private constant NFT_PER_SWAP = 1;

    event Minted(uint256[] ids, uint256[] values);
    event Claimed(address user, string destinationId, uint256 timestamp);
    event Swapped(address user, uint256 nftId);

    modifier validBatchInputLengths(
        uint256 _idsLength,
        uint256 _valuesLength,
        uint256 _pricesLength,
        uint256 _urisLength
    ) {
        require(
            _idsLength == _valuesLength &&
                _valuesLength == _pricesLength &&
                _pricesLength == _urisLength,
            "Mismatch between IDs, values, and URIs. Please ensure all inputs have the same length."
        );
        _;
    }

    modifier onlyFungibleTokenFormat(
        uint256 _id,
        uint256 _price,
        string memory _uri
    ) {
        require(
            _id == 0 && _price == 0 && bytes(_uri).length == 0,
            "To mint a fungible token, leave ID and price as 0, and URI empty."
        );
        _;
    }

    modifier oneClaimPerDay(string memory _destinationId, address _user) {
        require(
            block.timestamp >= lastClaims[_destinationId][_user] + 1 days,
            "You can only claim once per day for each destination."
        );
        _;
    }

    modifier matchNFTPrice(uint256 _nftId, uint256 _value) {
        require(
            prices[_nftId] == _value,
            "Price mismatch: the provided token amount does not match the NFT price."
        );
        _;
    }

    constructor() Ownable(msg.sender) ERC1155("") {
        _setBaseURI("https://gateway.pinata.cloud/ipfs/");
    }

    function mint(
        uint256[] memory _ids,
        uint256[] memory _values,
        uint256[] memory _prices,
        string[] memory _uris
    )
        external
        onlyOwner
        validBatchInputLengths(
            _ids.length,
            _values.length,
            _prices.length,
            _uris.length
        )
        onlyFungibleTokenFormat(_ids[0], _prices[0], _uris[0])
    {
        _mintBatch(address(this), _ids, _values, "");

        for (uint256 i = 0; i < _ids.length; i++) {
            prices[_ids[i]] = _prices[i];
            _setURI(_ids[i], _uris[i]);
        }

        emit Minted(_ids, _values);
    }

    function claim(
        string memory _destinationId,
        string[] memory _proofs
    ) external oneClaimPerDay(_destinationId, msg.sender) nonReentrant {
        lastClaims[_destinationId][msg.sender] = block.timestamp;

        proofs.push(
            Proof(_destinationId, msg.sender, block.timestamp, _proofs)
        );

        _safeTransferFrom(
            address(this),
            msg.sender,
            FUNGIBLE_TOKEN_ID,
            CLAIM_LIMIT_PER_DAY_PER_DESTINATION,
            ""
        );

        emit Claimed(msg.sender, _destinationId, block.timestamp);
    }

    function swap(
        uint256 _nftId,
        uint256 _value
    ) external matchNFTPrice(_nftId, _value) nonReentrant {
        _burn(msg.sender, FUNGIBLE_TOKEN_ID, _value);

        _safeTransferFrom(address(this), msg.sender, _nftId, NFT_PER_SWAP, "");

        emit Swapped(msg.sender, _nftId);
    }

    function tokenURI(uint256 _id) external view returns (string memory) {
        return uri(_id);
    }

    function balance(
        address _user,
        uint256 _id
    ) external view returns (uint256) {
        return balanceOf(_user, _id);
    }

    function getProofs() external view returns (Proof[] memory) {
        return proofs;
    }

    function getLastClaims(
        string memory _destinationId,
        address _user
    ) external view returns (uint256) {
        return lastClaims[_destinationId][_user];
    }

    function getNFTPrice(uint256 _id) external view returns (uint256) {
        return prices[_id];
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    //
}
