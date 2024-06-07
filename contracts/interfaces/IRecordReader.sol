// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRecordReader {
  /**
   * @dev Function to get record.
   * @param key The key to query the value of.
   * @param tokenId The token id to query.
   * @return The value string.
   */
  function get(string calldata key, uint256 tokenId) external view returns (string memory);

  /**
   * @dev Function to get multiple record.
   * @param keys The keys to query the value of.
   * @param tokenId The token id to query.
   * @return The values.
   */
  function getMany(string[] calldata keys, uint256 tokenId) external view returns (string[] memory);

  /**
   * @dev Function get value by provided key hash.
   * @param keyHash The key to query the value of.
   * @param tokenId The token id to query.
   */
  function getByHash(uint256 keyHash, uint256 tokenId) external view returns (string memory key, string memory value);

  /**
   * @dev Function get values by provided key hashes.
   * @param keyHashes The key to query the value of.
   * @param tokenId The token id to query.
   */
  function getManyByHash(
    uint256[] calldata keyHashes,
    uint256 tokenId
  ) external view returns (string[] memory keys, string[] memory values);

  /**
   * @dev Function get all keys associated with a token ID.
   * @param tokenId The token id to query.
   */
  function getKeysOf(uint256 tokenId) external view returns (string[] memory keys);
}
