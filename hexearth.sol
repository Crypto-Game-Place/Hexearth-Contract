// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CGPEarth is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public _owner;
    uint256 public parcelPrice = 0.00001 ether;

    constructor() ERC721("CGPEarh", "CGPE") {
        _tokenIds.increment();
        _owner = msg.sender;
    }

    struct Parcel {
        string h3id;
        uint256 tokenId;
    }

    struct ParcelList {
        string h3id;
        uint256 tokenId;
        address ownerId;
        string ipfs;
    }

    mapping(uint256 => string) private _tokenExists;
    mapping(uint256 => Parcel) private _parcels;

    function buyParcel(string memory h3id, string memory uri) public payable  {
        require(_h3idToTokenId(h3id) == 0, "Parcel already exists");

        require(bytes(uri).length > 0, "URI is empty");
        require(msg.value == parcelPrice, "Invalid price");

        uint256 tokenId = _tokenIds.current();
        _tokenIds.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenExists[tokenId] = h3id;
        _parcels[tokenId] = Parcel(h3id, tokenId);

        payable(_owner).transfer(parcelPrice);
         if (msg.value > parcelPrice) {
            payable(msg.sender).transfer(msg.value - parcelPrice);
        }
       
    }

    function getParcelsList() public view returns (ParcelList[] memory) {
        Parcel[] memory parcels = new Parcel[](_tokenIds.current());
        ParcelList[] memory parcelsLists = new ParcelList[](
            _tokenIds.current()
        );
        for (uint256 i = 1; i < _tokenIds.current(); i++) {
            parcels[i] = _parcels[i];
            parcelsLists[i] = ParcelList(
                parcels[i].h3id,
                parcels[i].tokenId,
                ownerOf(parcels[i].tokenId),
                tokenURI(parcels[i].tokenId)
            );
        }
        return parcelsLists;
    }

    function getParcel(
        string memory h3id
    ) public view returns (ParcelList memory) {
        uint256 tokenId = _h3idToTokenId(h3id);
        require(tokenId != 0, "Token not found");
        Parcel memory parcel = _parcels[tokenId];
        return
            ParcelList(
                parcel.h3id,
                parcel.tokenId,
                ownerOf(parcel.tokenId),
                tokenURI(parcel.tokenId)
            );
    }

    function _h3idToTokenId(string memory h3id) public view returns (uint256) {
        for (uint256 i = 1; i < _tokenIds.current(); i++) {
            if (
                keccak256(abi.encodePacked(_parcels[i].h3id)) ==
                keccak256(abi.encodePacked(h3id))
            ) {
                return i;
            }
        }
        return 0;
    }

    function _h3idOwner(string memory h3id) public view returns (address) {
        uint256 tokenId = _h3idToTokenId(h3id);
        require(tokenId != 0, "Token not found");
        return ownerOf(tokenId);
    }

    function _h3idTokenURI(
        string memory h3id
    ) public view returns (string memory) {
        uint256 tokenId = _h3idToTokenId(h3id);
        require(tokenId != 0, "Token not found");
        return tokenURI(tokenId);
    }

    modifier onlyOwner() {
        require(
            _owner == msg.sender,
            "Ownership Assertion: Caller of the function is not the owner."
        );
        _;
    }

    function setParcelPrice(uint256 newPrice) public onlyOwner {
        parcelPrice = newPrice;
    }
}
