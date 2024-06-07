// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./interfaces/IMetadata.sol";
import {IDomainRegistry} from "./interfaces/IDomainRegistry.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Tangiblink Domains NFT Metadata Contract used for generation of NFT metadata,

/// @custom:security-contact security@tangiblink.io
contract Metadata is IMetadata, Ownable {
  using Strings for uint256;

  address public s_domainRegistryAddress;
  IDomainRegistry internal domainRegistry;
  bool internal domainSet;
  // SVG components array
  string[] public svgStrings;
  // Metadata attribute components array
  string[] public attributeStrings;

  event SvgStringsSet();
  event AttributeStringsSet();

  error DomainRegistryOnly();
  error DomainRegistryAlreadySet();

  constructor() Ownable(_msgSender()) {}

  // Modifiers

  /**
   * @notice Modifier - Reverts if msgSender() is not the Function Consumer contract
   */
  modifier onlyDomainRegistry() {
    if (_msgSender() != s_domainRegistryAddress || !domainSet) {
      revert DomainRegistryOnly();
    }
    _;
  }

  /**
   * @notice Sets the Domain Registry Address. Only performed once after Domain registry deployment.
   * @param domainRegistryAddress The Domain Registry address.
   */
  function setDomainRegistry(address domainRegistryAddress) external override onlyOwner {
    if (domainSet) {
      revert DomainRegistryAlreadySet();
    }
    domainSet = true;
    s_domainRegistryAddress = domainRegistryAddress;
    domainRegistry = IDomainRegistry(domainRegistryAddress);
  }

  /**
   * @notice Compiles the SVG image data and encodes as Base64 for inclusion in TokenURI for marketplace metadata.
   * @param tokenId uint256 ID of the token
   * @param url Full URL (Base URI and Token ID combined)
   * @param plusCode - The google Plus Code for the Domain name location.
   */
  function generateImage(
    uint256 tokenId,
    string memory url,
    string memory plusCode
  ) internal view returns (string memory) {
    bytes memory svg = abi.encodePacked(
      abi.encodePacked(svgStrings[0], url),
      abi.encodePacked(svgStrings[1], plusCode),
      abi.encodePacked(svgStrings[2], tokenId.toString()),
      abi.encodePacked(
        svgStrings[3],
        uint256(uint160(IERC721(s_domainRegistryAddress).ownerOf(tokenId))).toHexString(20)
      ),
      svgStrings[4]
    );
    return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svg)));
  }

  /**
   * @notice Compiles the NFT metadata data for marketplace access to metadata through TokenURI function.
   * @param tokenId uint256 ID of the token
   */
  function getOnChainMetadata(uint256 tokenId) external view override onlyDomainRegistry returns (string memory) {
    string memory plusCode = domainRegistry.getPlusCode(tokenId);
    string memory url = string.concat(domainRegistry.getBaseURI(), plusCode);
    bytes memory dataURI = abi.encodePacked(
      abi.encodePacked(attributeStrings[0], plusCode),
      abi.encodePacked(attributeStrings[1], plusCode),
      abi.encodePacked(attributeStrings[2], unicode"⚠️"),
      abi.encodePacked(attributeStrings[3], url),
      abi.encodePacked(attributeStrings[4], generateImage(tokenId, url, plusCode)),
      attributeStrings[5]
    );
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
  }

  /**
   * @notice Sets the svgStrings storage array
   */
  function setSvgStringArray(string[] memory svgStringsArray) public override onlyOwner {
    svgStrings = svgStringsArray;
    emit SvgStringsSet();
  }

  /**
   * @notice Sets the attributeStrings storage array
   */
  function setAttributeStringArray(string[] memory attributeStringsArray) public override onlyOwner {
    attributeStrings = attributeStringsArray;
    emit AttributeStringsSet();
  }

  /**
   * @notice Returns the svgStrings storage array
   */
  function getSvgStringArray() public view override onlyOwner returns (string[] memory values) {
    values = new string[](svgStrings.length);
    for (uint256 i = 0; i < svgStrings.length; i++) {
      values[i] = svgStrings[i];
    }
  }

  /**
   * @notice Returns the attributeStrings storage array
   */
  function getAttributeStringArray() public view override onlyOwner returns (string[] memory values) {
    values = new string[](attributeStrings.length);
    for (uint256 i = 0; i < attributeStrings.length; i++) {
      values[i] = attributeStrings[i];
    }
  }
}
