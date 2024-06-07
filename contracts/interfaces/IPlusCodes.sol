// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Chainlink Functions client interface.
 */
interface IPlusCodes {
  /**
   * @notice Utilizes checkCode function to determine if code is valid.
   * Returns boolean depending on validity
   * @param _code The google Plus Code
   */
  function isValid(string memory _code) external pure returns (bool);

  /**
   * @notice Determines if a code is valid full Open Location Code.
   * To be valid, all characters must be from the Open Location Code character
   * set with only one separator. The separator can be in position eight only.
   * Not all possible combinations of Open Location Code characters decode to
   * valid latitude and longitude values. This checks that a code is valid
   * and also that the latitude and longitude values are legal. If the prefix
   * character is present, it must be the first character.
   * Example code: 8GWM4M34+8QR
   * Returns the Plus Code corrected to upper case if valid.
   * @param _code The google Plus Code
   */
  function checkCode(string memory _code) external pure returns (string memory);
}
