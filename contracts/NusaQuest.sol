// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {ERC1155URIStorage} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NusaQuest is ERC1155URIStorage, ERC1155Holder, Ownable {
    //
    // mapping(uint256 => string) private proofs;
    mapping(string => mapping(address => uint256)) lastClaims;

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

    function claim(string memory _destinationId, string[] memory _proofs) external {
        lastClaims[_destinationId][msg.sender] = block.timestamp;
        // proofs[_id] = _proof;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    //
}
