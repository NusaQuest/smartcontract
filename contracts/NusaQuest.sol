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
    // mapping(uint256 => string) private proofs;
    struct Proof {
        uint256 id;
        string destinationId;
        address user;
        uint256 timestamp;
        string[] proofs;
    }
    Proof[] private proofs;
    mapping(string => mapping(address => uint256)) lastClaims;
    uint256 private constant FUNGIBLE_TOKEN_ID = 0;
    uint256 private constant CLAIM_LIMIT_PER_DAY_PER_DESTINATION = 20;
    uint256 private constant NFT_PER_SWAP = 1;

    modifier validBatchInputLengths(
        uint256 _idsLength,
        uint256 _valuesLength,
        uint256 _urisLength
    ) {
        require(
            _idsLength == _valuesLength && _valuesLength == _urisLength,
            "Mismatch between IDs, values, and URIs. Please ensure all inputs have the same length."
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

    constructor() Ownable(msg.sender) ERC1155("") {
        _setBaseURI("https://gateway.pinata.cloud/ipfs/");
    }

    function mint(
        uint256[] memory _ids,
        uint256[] memory _values,
        string[] memory _uris
    )
        external
        onlyOwner
        validBatchInputLengths(_ids.length, _values.length, _uris.length)
    {
        _mintBatch(address(this), _ids, _values, "");

        for (uint256 i = 0; i < _ids.length; i++) {
            _setURI(_ids[i], _uris[i]);
        }
    }

    function claim(
        string memory _destinationId,
        string[] memory _proofs
    ) external oneClaimPerDay(_destinationId, msg.sender) nonReentrant {
        lastClaims[_destinationId][msg.sender] = block.timestamp;

        proofs.push(
            Proof(
                proofs.length,
                _destinationId,
                msg.sender,
                block.timestamp,
                _proofs
            )
        );

        _safeTransferFrom(
            address(this),
            msg.sender,
            FUNGIBLE_TOKEN_ID,
            CLAIM_LIMIT_PER_DAY_PER_DESTINATION,
            ""
        );
    }

    function swap(uint256 _nftId, uint256 _value) external nonReentrant {
        _burn(msg.sender, FUNGIBLE_TOKEN_ID, _value);

        _safeTransferFrom(address(this), msg.sender, _nftId, NFT_PER_SWAP, "");
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    //
}
