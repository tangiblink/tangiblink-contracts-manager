// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import {StringUtilsLib} from "./StringUtilsLib.sol";
import {IPlusCodes} from "./interfaces/IPlusCodes.sol";

contract PlusCodes is IPlusCodes {
  using StringUtilsLib for string;

  constructor() {}

  //
  // Open Location Codes are short, 11 character codes (12 including '+') that can be used instead
  // of street addresses. The codes can be generated and decoded offline, and use
  // a reduced character set that minimises the chance of codes including words.
  //

  // A separator used to break the code into two parts to aid memorability.
  string private constant SEPARATOR_ = "+";

  // The number of characters to place before the separator.
  uint private constant SEPARATOR_POSITION_ = 8;

  // The character used to pad codes.
  string private constant PADDING_CHARACTER_ = "0";

  // The character set used to encode the values.
  string private constant CODE_ALPHABET_ = "23456789CFGHJMPQRVWX";

  // The base to use to convert numbers to/from.
  uint private constant ENCODING_BASE_ = 20;

  // The maximum value for latitude in degrees.
  uint private constant LATITUDE_MAX_ = 180;

  // The maximum value for longitude in degrees.
  uint private constant LONGITUDE_MAX_ = 360;

  // The max number of digits to process in a Plus Code.
  uint private constant CODE_LENGTH_ = 12;

  /**
   * @notice Utilizes checkCode function to determine if code is valid.
   * Returns boolean depending on validity
   * @param _code The google Plus Code
   */

  function isValid(string memory _code) public pure override returns (bool) {
    if (bytes(checkCode(_code)).length == 0) {
      return false;
    }
    return true;
  }

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
  function checkCode(string memory _code) public pure override returns (string memory) {
    // code length is correct?
    if (!(bytes(_code).length == CODE_LENGTH_)) {
      return "";
    }
    string memory code = _code.toUpperCase();
    // The separator is required.
    (bool sepExists, int256 sepPos) = code.matchStr(SEPARATOR_);
    if (!sepExists) {
      return "";
    }
    // Code cannot contain more than one seperator
    // allIndexOf returns an additional index value of '0' at the end of all returned arrays as default.
    // therfore a string containing one character position will return an array length of 2.
    if (code.lastIndexOf(SEPARATOR_) != uint256(sepPos)) {
      return "";
    }
    // Is seperator in an illegal position?
    if (uint256(sepPos) != SEPARATOR_POSITION_) {
      return "";
    }
    // Check the code contains only valid characters and cannot be padded.
    for (uint i = 0; i < bytes(code).length; i++) {
      string memory ch = code.charAt(i);
      if (!CODE_ALPHABET_.includes(ch) && !SEPARATOR_.includes(ch)) {
        return "";
      }
    }
    // Work out what the first latitude character indicates for latitude.
    string memory firstLatChar = code.charAt(0);
    uint256 firstLatValue = CODE_ALPHABET_.indexOf(firstLatChar.toUpperCase()) * ENCODING_BASE_;
    if (firstLatValue >= LATITUDE_MAX_) {
      // The code would decode to a latitude of >= 90 degrees.
      return "";
    }
    // Work out what the first longitude character indicates for longitude.
    string memory firstLonChar = code.charAt(1);
    uint256 firstLngValue = CODE_ALPHABET_.indexOf(firstLonChar.toUpperCase()) * ENCODING_BASE_;
    if (firstLngValue >= LONGITUDE_MAX_) {
      // The code would decode to a longitude of >= 180 degrees.
      return "";
    }
    return code;
  }
}
