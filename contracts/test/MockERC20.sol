// SPDX-License-Identifier: MIT

// @dev This contract has been adapted to fit with dappTools
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
  uint256 constant INITIAL_SUPPLY = 1000000000000000000000000;

  constructor() ERC20("MockERC20", "MOCK") {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
}
