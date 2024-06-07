// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC4907.sol";
import "./IPlusCodes.sol";
import "./IRecordStorage.sol";

/**
 * @title Chainlink Functions client interface.
 */
interface IDomainRegistry is IERC4907, IPlusCodes {
  // Emergency functions

  function pause() external;

  function unpause() external;

  /**
   * @dev Transfer domain ownership without resetting domain records.
   * @param to address of new domain owner
   * @param tokenId uint256 ID of the token to be transferred
   */
  function setOwner(address to, uint256 tokenId) external;

  /**
   * @dev Returns whether the given spender can transfer a given token ID.
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   * is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);

  /**
   * @notice Initiate the minting of an individual plusCode.
   * @param plusCode - The google Plus Code for the Domain name location.
   */
  function mint(string memory plusCode) external payable;

  /**
   * @dev mints token with records
   * @param plusCode - The google Plus Code for the Domain name location.
   * @param keys New record keys
   * @param values New record values
   */
  function mintWithRecords(string calldata plusCode, string[] calldata keys, string[] calldata values) external payable;

  /**
   * @notice Gets the price from the latest round data of Chainlink price feeds
   * @return usdPerWei The amount of USD in per unit of MATIC in wei.
   */
  function getFeedData() external view returns (int256);

  /**
   * @notice Checks the price of minting a domain
   * @return maticWei The amount of MATIC in wei equivelent to the USD cost.
   */
  function checkPrice() external view returns (uint256);

  /**
   * @notice Converts plusCode name string to a unique uint256 for use as Token ID.
   * @param plusCode - The google Plus Code for the Domain name location.
   */
  function plusCodeToTokenId(string memory plusCode) external pure returns (uint256);

  /**
   * @notice Set a new Base URI for concatenation with Token ID to form the full Token URI.
   * @param _newBaseURI - The first fixed part of the full Token URI.
   */
  function setBaseURI(string memory _newBaseURI) external;

  /**
   * @notice Get token baseURI
   */
  function getBaseURI() external view returns (string memory);

  /**
   * @notice Get Plus Code from the token ID
   * @param tokenId The NFT to get the user address for
   * @return The Plus Code for this NFT
   */
  function getPlusCode(uint256 tokenId) external view returns (string memory);

  /**
   * @notice Getter function for retrieving the Metadata contract address
   */
  function getMetadataContractAddress() external view returns (address);

  /**
   * @notice Getter function for retrieving the Price Feed contract address
   */
  function getPriceFeedContractAddress() external view returns (address);

  /**
   * @notice Gets the number of minted tokenIds
   */
  function getTokenIdsCount() external view returns (uint256 count);

  /**
   * @notice Returns the array of token Ids stored in the tokenIds array
   */
  function getTokenIdsArray(uint256 start, uint256 finish) external view returns (uint256[] memory);

  /**
   * @notice Returns the array of Plus Codes stored in the plusCodes array
   */
  function getPlusCodesArray(uint256 start, uint256 finish) external view returns (string[] memory);

  /**
   * @notice Returns an array of token owners in the order of the tokenIds array
   */
  function getOwnersArray(uint256 start, uint256 finish) external view returns (address[] memory);

  /**
   * @notice Returns an array of token users in the order of the tokenIds array
   */
  function getUsersArray(uint256 start, uint256 finish) external view returns (address[] memory);

  /**
   * @notice Set a new Price Feed address for the Matic to USD conversion.
   * @param _newPriceFeedAddress address of the chainlink price feed.
   */
  function updatePriceFeedContract(address _newPriceFeedAddress) external;

  /**
   * @notice Set a new Contract address for the metadata generating contract.
   * @param _newMetaDataContract address of the metadata generating contract.
   */
  function updateMetadataContract(address _newMetaDataContract) external;

  /**
   * @notice Set a new Contract URI for OpenSea contract metadata.
   * @param _newContractURI URI of the contract level metadata.
   */
  function setContractURI(string memory _newContractURI) external;

  /**
   * @notice For OpenSea contract level metadata.
   */
  function contractURI() external view returns (string memory);

  /**
   * @notice Set a new payment fee percent. Value of 100 = 1%, 1000 = 10%, 10000 = 100%
   * @param _newFeePercent New fee percent division value.
   */
  function setNewFeePercent(uint _newFeePercent) external;

  /**
   * @notice Gets the fee to deduct from a payment.
   * @param amount The amount of the specified token to be withdrawn.
   * @param gasprice The current gasprice for the transaction.
   * @return fee The fee amount in MATIC wei.
   */
  function getPaymentFee(uint amount, uint gasprice) external view returns (uint256);

  /**
   * @notice Allows payment amount of native token to be sent to a user.
   * @param tokenId uint256 ID of the token
   * @param data string reason for transfer
   */
  function payDomain(uint256 tokenId, string calldata data) external payable returns (bool);

  /**
   * @notice Allows payment amount of native token to be sent to a domain user.
   * @param addressTo The address to send the token to.
   * @param data string reason for transfer
   */
  function payAccount(address payable addressTo, string calldata data) external payable returns (bool);

  /**
   * @notice Allows contract owner to withdraw an amount of native token from the contract balance.
   */
  function withdraw(address payable addressTo, uint amount) external returns (bool);

  /**
   * @notice Allows contract owner to withdraw an amount of a specified ERC20 token from the contract balance.
   * @param tokenAddress The address of the ERC-20 compliant token.
   * @param addressTo The address to send to token to.
   * @param amount The amount of the specified token to be withdrawn.
   */
  function withdrawErc20(address tokenAddress, address payable addressTo, uint amount) external returns (bool);

  /**
   * @dev Existence of token.
   * @param tokenId uint256 ID of the token
   */
  function exists(uint256 tokenId) external view returns (bool);

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   * Requirements:
   * - `tokenId` must exist.
   * @param spender Address of account being queried
   * @param tokenId uint256 ID of the token
   */
  function isUserOrApproved(address spender, uint256 tokenId) external view returns (bool);

  /**@notice Burns tokens
   * @param tokenId uint256 ID of the token
   */
  function burn(uint256 tokenId) external;
}
