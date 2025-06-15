// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NusaQuest is ERC721URIStorage, ERC721Holder, Ownable {
    //
    mapping(uint256 => string) private proofs;

    constructor() Ownable(msg.sender) ERC721("NusaQuest", "NQT") {}

    function mintNFT(uint256 _id, string memory _uri) external onlyOwner {
        _safeMint(address(this), _id);
        _setTokenURI(_id, _uri);
    }

    function claimNFT(uint256 _id, string memory _proof) external {
        proofs[_id] = _proof;
    }
    //
}
