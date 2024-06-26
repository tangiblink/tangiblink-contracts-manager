// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract KeyStorage {
  mapping(uint256 => string) private _keys;

  function getKey(uint256 keyHash) public view returns (string memory) {
    return _keys[keyHash];
  }

  function getKeys(uint256[] calldata hashes) public view returns (string[] memory values) {
    return _getKeys(hashes);
  }

  function addKey(string memory key) external {
    _addKey(uint256(keccak256(abi.encodePacked(key))), key);
  }

  function _existsKey(uint256 keyHash) internal view returns (bool) {
    return bytes(_keys[keyHash]).length > 0;
  }

  function _addKey(uint256 keyHash, string memory key) internal {
    if (!_existsKey(keyHash)) {
      _keys[keyHash] = key;
    }
  }

  function _getKeys(uint256[] memory hashes) internal view returns (string[] memory values) {
    values = new string[](hashes.length);
    for (uint256 i = 0; i < hashes.length; i++) {
      values[i] = _keys[hashes[i]];
    }
  }
}
