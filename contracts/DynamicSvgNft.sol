// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//imports
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";
import "hardhat/console.sol";

//errors
error ERC721Metadata__URI_QueryFor_NonExistentToken();

//contract

contract DynamicSvgNft is ERC721, Ownable {
    //vars
    uint256 private s_tokenCounter;
    string private s_lowImageUri;
    string private s_highImageUri;

    mapping(uint256 => int256) private s_tokenIdToHighValues;
    AggregatorV3Interface internal immutable i_priceFeed;

    //events
    event CreatedNFT(uint256 indexed tokenId, int256 highValue);

    //constructor
    constructor(
        address priceFeedAddress,
        string memory lowSvg,
        string memory highSvg
    ) ERC721("DynamicSvgNft", "DSN") {
        s_tokenCounter = 0;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
        s_lowImageUri = svgToImageURI(lowSvg);
        s_highImageUri = svgToImageURI(highSvg);
    }

    function mintNft(int256 highValue) public {
        s_tokenIdToHighValues[s_tokenCounter] = highValue;
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenCounter = s_tokenCounter + 1;
        emit CreatedNFT(s_tokenCounter, highValue);
    }

    //converting raw svg to hash format and gives imageURI
    function svgToImageURI(
        string memory svg
    ) public pure returns (string memory) {
        string memory baseUrl = "data:image/svg+xml;base64,";

        //following line will convert svg to bytecode
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg)))
        );

        //concate two strings at byte level(low level) and returns full URI
        return string(abi.encodePacked(baseUrl, svgBase64Encoded));
    }

    //returns base URI
    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    //this will generate the token uri in which the metadata of token will be encoded
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }

        (, int256 price, , , ) = i_priceFeed.latestRoundData();
        string memory imageURI = s_lowImageUri;
        if (price >= s_tokenIdToHighValues[tokenId]) {
            imageURI = s_highImageUri;
        }
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(), // You can add whatever name here
                                '", "description":"An NFT that changes based on the Chainlink Feed", ',
                                '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    //getter functions for public use

    function getLowSVG() public view returns (string memory) {
        return s_lowImageUri;
    }

    function getHighSVG() public view returns (string memory) {
        return s_highImageUri;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}
