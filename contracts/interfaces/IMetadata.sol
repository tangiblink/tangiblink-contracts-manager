// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions client interface.
 */
interface IMetadata {
  /**
   * @notice Sets the Domain Registry Address. Only performed once after Domain registry deployment.
   * @param domainRegistryAddress The Domain Registry address.
   */
  function setDomainRegistry(address domainRegistryAddress) external;

  /**
   * @notice Compiles the NFT metadata data for marketplace access to metadata through TokenURI function.
   * @param tokenId uint256 ID of the token
   */
  function getOnChainMetadata(uint256 tokenId) external view returns (string memory);

  /**
   * @notice Sets the svgStrings storage array
   */
  function setSvgStringArray(string[] memory svgStringsArray) external;

  /**
   * @notice Sets the attributeStrings storage array
   */
  function setAttributeStringArray(string[] memory attributeStringsArray) external;

  /**
   * @notice Returns the svgStrings storage array
   */
  function getSvgStringArray() external view returns (string[] memory values);

  /**
   * @notice Returns the attributeStrings storage array
   */
  function getAttributeStringArray() external view returns (string[] memory values);
}
