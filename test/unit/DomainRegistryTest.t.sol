pragma solidity >=0.6.0 <0.9.0;

import "forge-std/Test.sol";
import {DomainRegistry} from "../../contracts/DomainRegistry.sol";
import {Metadata} from "../../contracts/Metadata.sol";
import {MockV3Aggregator} from "../../contracts/test/MockV3Aggregator.sol";
import {HelperConfig} from "../../scripts/HelperConfig.s.sol";
import {TestEventsAndErrors} from "../../scripts/TestEventsAndErrors.s.sol";
import {StringUtilsLib} from "../../contracts/StringUtilsLib.sol";
import {MockERC20} from "../../contracts/test/MockERC20.sol";

contract DomainRegistryTest is Test, TestEventsAndErrors {
  using StringUtilsLib for string;
  HelperConfig public helperConfig;
  DomainRegistry public domainRegistry;
  Metadata public metadata;
  MockV3Aggregator public usdPriceFeed;
  string CODE_ALPHABET_ = "23456789CFGHJMPQRVWX";
  address public zeroAddress = address(0);
  address public DEPLOYER;
  address public USER = makeAddr("user");
  uint256 public constant STARTING_USER_BALANCE = 10 ether;
  uint public constant SEPARATOR_POSITION_ = 8;
  string public constant SEPARATOR_ = "+";
  string baseURL;
  uint256 mintCostUsd;
  uint256 feePercent;
  address domainRegistryAddress;
  address metadataAddress;
  address usdPriceFeedAddress;
  string testPlusCode;
  uint256 mintCost;
  uint256 randomPlusCodeCount;
  string[] testKeys = new string[](2);
  string[] testValues = new string[](2);

  function setUp() external {
    helperConfig = new HelperConfig();
    (baseURL, mintCostUsd, feePercent, domainRegistryAddress, metadataAddress, usdPriceFeedAddress) = helperConfig
      .activeNetworkConfig();
    domainRegistry = DomainRegistry(payable(domainRegistryAddress));
    metadata = Metadata(metadataAddress);
    usdPriceFeed = MockV3Aggregator(usdPriceFeedAddress);
    vm.deal(USER, STARTING_USER_BALANCE);
    testPlusCode = randomPlusCode();
    mintCost = domainRegistry.checkPrice();
    console.log("Test Plus Code: %s", testPlusCode);
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(testPlusCode);
    vm.stopPrank();
    DEPLOYER = domainRegistry.owner();
    console.log("owner: s%", DEPLOYER);
    testKeys[0] = "key_1";
    testKeys[1] = "key_2";
    testValues[0] = "value_1";
    testValues[1] = "value_2";
  }

  function randomPlusCode() public returns (string memory plusCode) {
    bytes memory codeBytes = new bytes(12);
    bool validCode = false;
    while (!validCode) {
      for (uint i = 0; i < 12; i++) {
        if (i != SEPARATOR_POSITION_) {
          uint256 randomNumber = uint(
            keccak256(abi.encodePacked(block.prevrandao, block.timestamp, CODE_ALPHABET_, i, randomPlusCodeCount))
          );
          uint256 randomIndex = randomNumber % bytes(CODE_ALPHABET_).length;
          codeBytes[i] = bytes(CODE_ALPHABET_)[randomIndex];
        } else {
          codeBytes[i] = bytes(SEPARATOR_)[0];
        }
        randomPlusCodeCount++;
      }
      validCode = domainRegistry.isValid(string(codeBytes));
    }
    return string(codeBytes);
  }

  function randomInvalidPlusCode() public returns (string memory plusCode) {
    bytes memory codeBytes = new bytes(12);
    bool inValidCode = false;
    while (!inValidCode) {
      for (uint i = 0; i < 12; i++) {
        if (i != SEPARATOR_POSITION_) {
          uint256 randomNumber = uint(
            keccak256(abi.encodePacked(block.prevrandao, block.timestamp, CODE_ALPHABET_, i, randomPlusCodeCount))
          );
          uint256 randomIndex = randomNumber % bytes(CODE_ALPHABET_).length;
          codeBytes[i] = bytes(CODE_ALPHABET_)[randomIndex];
        } else {
          codeBytes[i] = bytes(SEPARATOR_)[0];
        }
        randomPlusCodeCount++;
      }
      inValidCode = !domainRegistry.isValid(string(codeBytes));
    }
    return string(codeBytes);
  }

  // storage
  function test_s_baseURI() public {
    assertEq(baseURL, domainRegistry.s_baseURI());
  }

  function test_s_mintCostUsd() public {
    assertEq(mintCostUsd, domainRegistry.s_mintCostUsd());
  }

  function test_s_feePercent() public {
    assertEq(feePercent, domainRegistry.s_feePercent());
  }

  function test_tokenIds() public {
    string memory plusCode = randomPlusCode();
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    assertEq(tokenId, domainRegistry.tokenIds(domainRegistry.getTokenIdsCount() - 1));
  }

  function test_MAX_UINT256() public {
    assertEq(type(uint256).max, domainRegistry.MAX_UINT256());
    assertEq(
      115792089237316195423570985008687907853269984665640564039457584007913129639935,
      domainRegistry.MAX_UINT256()
    );
  }

  function test_s_tokenIdToPlusCode() public {
    string memory plusCode = randomPlusCode();
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    assertEq(plusCode, domainRegistry.s_tokenIdToPlusCode(tokenId));
  }

  // // Modifiers

  function test_OnlyApprovedOrOwner() public {
    address from = makeAddr("from");
    vm.deal(from, STARTING_USER_BALANCE);
    string memory plusCode = randomPlusCode();
    address to = makeAddr("to");
    vm.deal(to, STARTING_USER_BALANCE);
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain with records
    vm.startPrank(from);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    // Try to transfer using an unapproved account - expect revert
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, USER, tokenId));
    domainRegistry.transferFrom(from, to, tokenId);
    vm.stopPrank();
    // Set approval for USER address - expect emit
    vm.startPrank(from);
    vm.expectEmit(domainRegistryAddress);
    emit Approval(from, USER, tokenId);
    domainRegistry.approve(USER, tokenId);
    vm.stopPrank();
    // Transfer using an approved account - expect emit
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(from, to, tokenId);
    domainRegistry.transferFrom(from, to, tokenId);
    assertEq(to, domainRegistry.ownerOf(tokenId));
    vm.stopPrank();
    // Transfer using the owner account - expect emit
    vm.startPrank(to);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(to, from, tokenId);
    domainRegistry.transferFrom(to, from, tokenId);
    assertEq(from, domainRegistry.ownerOf(tokenId));
    vm.stopPrank();
  }

  function test_OnlyUserOrApproved() public {
    string memory plusCode = randomPlusCode();
    address approvedUser = makeAddr("approvedUser");
    address unapprovedUser = makeAddr("unapprovedUser");
    address renter = makeAddr("renter");
    uint64 expires = uint64(block.timestamp + 1 minutes);
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Reverts if token does not exist
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(ERC721NonexistentToken.selector, tokenId));
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    // Mint new random domain
    domainRegistry.mint{value: mintCost}(plusCode);
    // Set approval for approvedUser address - expect emit
    vm.expectEmit(domainRegistryAddress);
    emit Approval(USER, approvedUser, tokenId);
    domainRegistry.approve(approvedUser, tokenId);
    // Set records disallowed by unapprovedUser
    vm.startPrank(unapprovedUser);
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, unapprovedUser, tokenId));
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    vm.stopPrank();
    // Set records disallowed by 'renter' before set as userOf token
    vm.startPrank(renter);
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, renter, tokenId));
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    vm.stopPrank();
    // Set records allowed by 'owner'
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit NewKey(tokenId, testKeys[0], testKeys[0]);
    vm.expectEmit(domainRegistryAddress);
    emit Set(tokenId, testKeys[0], testValues[0], testKeys[0], testValues[0]);
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    // Reset token records to Null
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    domainRegistry.reset(tokenId);
    vm.stopPrank();
    // Set records allowed by 'approvedUser'
    vm.startPrank(approvedUser);
    vm.expectEmit(domainRegistryAddress);
    emit NewKey(tokenId, testKeys[0], testKeys[0]);
    vm.expectEmit(domainRegistryAddress);
    emit Set(tokenId, testKeys[0], testValues[0], testKeys[0], testValues[0]);
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    // Reset token records to Null
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    domainRegistry.reset(tokenId);
    vm.stopPrank();
    // Set user to the 'renter' address
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit UpdateUser(tokenId, renter, expires);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    domainRegistry.setUser(tokenId, renter, expires);
    vm.stopPrank();
    // Set records disallowed by token owner after 'renter' set as userOf token
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, USER, tokenId));
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    vm.stopPrank();
    // Set records disallowed by 'approvedUser' after 'renter' set as userOf token
    vm.startPrank(approvedUser);
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, approvedUser, tokenId));
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    vm.stopPrank();
    // Set records allowed by 'renter'
    vm.startPrank(renter);
    vm.expectEmit(domainRegistryAddress);
    emit NewKey(tokenId, testKeys[0], testKeys[0]);
    vm.expectEmit(domainRegistryAddress);
    emit Set(tokenId, testKeys[0], testValues[0], testKeys[0], testValues[0]);
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    // Reset token records to Null
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    domainRegistry.reset(tokenId);
    vm.stopPrank();
  }

  function test_InvalidPlusCode() public {
    string memory plusCode = randomPlusCode();
    string memory invalidPlusCode = randomInvalidPlusCode();
    string memory invalidCharacterCode = plusCode.replaceOne(plusCode.charAt(0), "N");
    string memory noSeperatorCode = plusCode.replaceOne(plusCode.charAt(8), "");
    string memory seperatorReplacedCode = plusCode.replaceOne(plusCode.charAt(8), "M");
    string memory shortCode = plusCode.replaceOne(plusCode.charAt(11), "");
    string memory longCode = plusCode.replaceOne(plusCode.charAt(11), "M5");
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Valid code mints correctly
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(zeroAddress, USER, tokenId);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    domainRegistry.mint{value: mintCost}(plusCode);
    assertTrue(domainRegistry.exists(tokenId));
    // Invalid Plus Code reverts with InvalidPlusCode
    vm.expectRevert(abi.encodeWithSelector(InvalidPlusCode.selector, invalidPlusCode));
    domainRegistry.mint{value: mintCost}(invalidPlusCode);
    // Invalid character Plus Code reverts with InvalidPlusCode
    vm.expectRevert(abi.encodeWithSelector(InvalidPlusCode.selector, invalidCharacterCode));
    domainRegistry.mint{value: mintCost}(invalidCharacterCode);
    // No seperator in Code reverts with InvalidPlusCode
    vm.expectRevert(abi.encodeWithSelector(InvalidPlusCode.selector, noSeperatorCode));
    domainRegistry.mint{value: mintCost}(noSeperatorCode);
    // Seperator replaced in Code reverts with InvalidPlusCode
    vm.expectRevert(abi.encodeWithSelector(InvalidPlusCode.selector, seperatorReplacedCode));
    domainRegistry.mint{value: mintCost}(seperatorReplacedCode);
    // Short Code reverts with InvalidPlusCode
    vm.expectRevert(abi.encodeWithSelector(InvalidPlusCode.selector, shortCode));
    domainRegistry.mint{value: mintCost}(shortCode);
    // Long Code reverts with InvalidPlusCode
    vm.expectRevert(abi.encodeWithSelector(InvalidPlusCode.selector, longCode));
    domainRegistry.mint{value: mintCost}(longCode);
    // Empty Plus Code reverts with InvalidPlusCode
    vm.expectRevert(abi.encodeWithSelector(InvalidPlusCode.selector, ""));
    domainRegistry.mint{value: mintCost}("");
    vm.stopPrank();
  }

  function test_Payment() public {
    string memory plusCode = randomPlusCode();
    uint256 lowValue = mintCost - 1;
    uint256 highValue = mintCost * 2;
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    vm.startPrank(USER);
    // Low payment reverts with NotEnoughWei
    vm.expectRevert(abi.encodeWithSelector(NotEnoughWei.selector, mintCost, lowValue));
    domainRegistry.mint{value: lowValue}(plusCode);
    // No payment reverts with NotEnoughWei
    vm.expectRevert(abi.encodeWithSelector(NotEnoughWei.selector, mintCost, 0));
    domainRegistry.mint(plusCode);
    // Over payment mints correctly and refunds difference
    vm.expectEmit(domainRegistryAddress);
    emit RefundOverpayment(USER, mintCost);
    domainRegistry.mint{value: highValue}(plusCode);
    assertTrue(domainRegistry.exists(tokenId));
    vm.stopPrank();
  }

  // // Emergency functions

  function test_Pause_Unpause() public {
    vm.startPrank(USER);
    string memory plusCode = randomPlusCode();
    // Try to pause with unapproved account - expect revert
    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
    domainRegistry.pause();
    vm.stopPrank();
    // Contract owner can pause
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit Paused(DEPLOYER);
    domainRegistry.pause();
    vm.stopPrank();
    // Reverts if user tries to mint (whenNotPaused)
    vm.startPrank(USER);
    vm.expectRevert(EnforcedPause.selector);
    domainRegistry.mint{value: mintCost}(plusCode);
    // Try to unpause with unapproved account - expect revert
    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
    domainRegistry.unpause();
    // Contract owner can unpause
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit Unpaused(DEPLOYER);
    domainRegistry.unpause();
    vm.stopPrank();
  }

  // Transferring

  function test_SetOwner() public {
    string memory plusCode = randomPlusCode();
    address to = makeAddr("to");
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    // Try to set owner with unapproved account - expect revert
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, address(this), tokenId));
    domainRegistry.setOwner(to, tokenId);
    // Token owner sets owner to new address - expect emit
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(USER, to, tokenId);
    domainRegistry.setOwner(to, tokenId);
    vm.stopPrank();
  }

  function test_TransferFrom() public {
    address from = makeAddr("from");
    vm.deal(from, STARTING_USER_BALANCE);
    string memory plusCode = randomPlusCode();
    address to = makeAddr("to");
    vm.deal(to, STARTING_USER_BALANCE);
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain with records
    vm.startPrank(from);
    domainRegistry.mintWithRecords{value: mintCost}(plusCode, testKeys, testValues);
    vm.stopPrank();
    // Assert records have been set
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    for (uint i = 0; i < keysOf.length; i++) {
      assertEq(keysOf[i], testKeys[i]);
      assertEq(valuesOf[i], testValues[i]);
    }
    // Try to transfer using an unapproved account - expect revert
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, USER, tokenId));
    domainRegistry.transferFrom(from, to, tokenId);
    vm.stopPrank();
    // Token owner sets approval for 'USER' address for use of the tokenId - expect emit
    vm.startPrank(from);
    vm.expectEmit(domainRegistryAddress);
    emit Approval(from, USER, tokenId);
    domainRegistry.approve(USER, tokenId);
    vm.stopPrank();
    // Try to transfer using an approved account - expect emit
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(from, to, tokenId);
    domainRegistry.transferFrom(from, to, tokenId);
    vm.stopPrank();
    // Expect records to have been reset
    string[] memory keysOfAfter = domainRegistry.getKeysOf(tokenId);
    uint256 keysLength = keysOfAfter.length;
    assertEq(keysLength, 0);
    // Try to transfer using token owner 'to' account back to the 'from' account - expect emit
    vm.startPrank(to);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(to, from, tokenId);
    domainRegistry.transferFrom(to, from, tokenId);
    vm.stopPrank();
  }

  function test_SafeTransferFrom() public {
    address from = makeAddr("from");
    vm.deal(from, STARTING_USER_BALANCE);
    string memory plusCode = randomPlusCode();
    address to = makeAddr("to");
    vm.deal(to, STARTING_USER_BALANCE);
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain with records
    vm.startPrank(from);
    domainRegistry.mintWithRecords{value: mintCost}(plusCode, testKeys, testValues);
    vm.stopPrank();
    // Assert records have been set
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    for (uint i = 0; i < keysOf.length; i++) {
      assertEq(keysOf[i], testKeys[i]);
      assertEq(valuesOf[i], testValues[i]);
    }
    // Try to transfer using an unapproved account - expect revert
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, USER, tokenId));
    domainRegistry.safeTransferFrom(from, to, tokenId, "");
    vm.stopPrank();
    // Token owner sets approval for 'USER' address for use of the tokenId - expect emit
    vm.startPrank(from);
    vm.expectEmit(domainRegistryAddress);
    emit Approval(from, USER, tokenId);
    domainRegistry.approve(USER, tokenId);
    vm.stopPrank();
    // Try to transfer using an approved account - expect emit
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(from, to, tokenId);
    domainRegistry.safeTransferFrom(from, to, tokenId, "");
    vm.stopPrank();
    // Expect records to have been reset
    string[] memory keysOfAfter = domainRegistry.getKeysOf(tokenId);
    uint256 keysLength = keysOfAfter.length;
    assertEq(keysLength, 0);
    // Try to transfer using token owner 'to' account back to the 'from' account - expect emit
    vm.startPrank(to);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(to, from, tokenId);
    domainRegistry.safeTransferFrom(to, from, tokenId, "");
    vm.stopPrank();
  }

  // /// Ownership

  function test_IsApprovedOrOwner() public {
    string memory plusCode = randomPlusCode();
    address approvedUser = makeAddr("approvedUser");
    address unapprovedUser = makeAddr("unapprovedUser");
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    // Token owner sets approval for 'approvedUser' address for use of the tokenId - expect emit
    vm.expectEmit(domainRegistryAddress);
    emit Approval(USER, approvedUser, tokenId);
    domainRegistry.approve(approvedUser, tokenId);
    vm.stopPrank();
    assertTrue(domainRegistry.isApprovedOrOwner(USER, tokenId));
    assertTrue(domainRegistry.isApprovedOrOwner(approvedUser, tokenId));
    assertTrue(!(domainRegistry.isApprovedOrOwner(unapprovedUser, tokenId)));
  }

  function test_Mint() public {
    string memory plusCode = randomPlusCode();
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain - emits events
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(zeroAddress, USER, tokenId);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    // token exist - assert
    assertTrue(domainRegistry.exists(tokenId));
  }

  function test_MintWithRecords() public {
    string memory plusCode = randomPlusCode();
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain with records - emits events
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(zeroAddress, USER, tokenId);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    for (uint i = 0; i < testKeys.length; i++) {
      vm.expectEmit(domainRegistryAddress);
      emit NewKey(tokenId, testKeys[i], testKeys[i]);
      vm.expectEmit(domainRegistryAddress);
      emit Set(tokenId, testKeys[i], testValues[i], testKeys[i], testValues[i]);
    }
    domainRegistry.mintWithRecords{value: mintCost}(plusCode, testKeys, testValues);
    vm.stopPrank();
    // token exist - assert
    assertTrue(domainRegistry.exists(tokenId));
    // Expect records to have been set
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    for (uint i = 0; i < keysOf.length; i++) {
      assertEq(keysOf[i], testKeys[i]);
      assertEq(valuesOf[i], testValues[i]);
    }
  }

  function test_GetFeedData() public {
    int256 usdPerWei = domainRegistry.getFeedData();
    (, int256 latestPrice, , , ) = usdPriceFeed.latestRoundData();
    assertGt(usdPerWei, 0);
    assertEq(usdPerWei, latestPrice);
  }

  function test_CheckPrice() public {
    uint256 price = domainRegistry.checkPrice();
    assertGt(price, 0);
  }

  function test_PlusCodeToTokenId() public {
    string memory plusCode = randomPlusCode();
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    assertEq(tokenId, uint256(keccak256(abi.encodePacked(plusCode))));
  }

  function test_SetBaseURI() public {
    string memory _newBaseURI = "Test_New_Base_URI";
    // Only owner can update
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
    domainRegistry.setBaseURI(_newBaseURI);
    vm.stopPrank();
    // Update the base URI - emits events
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit NewBaseURI(_newBaseURI);
    domainRegistry.setBaseURI(_newBaseURI);
    // Stored base URI now matches new base URI
    assertEq(domainRegistry.s_baseURI(), _newBaseURI);
    // Reset base URI to original
    vm.expectEmit(domainRegistryAddress);
    emit NewBaseURI(baseURL);
    domainRegistry.setBaseURI(baseURL);
    // Stored base URI now matches original base URI
    assertEq(domainRegistry.s_baseURI(), baseURL);
    vm.stopPrank();
  }

  function test_GetPriceFeedContractAddress() public {
    assertEq(usdPriceFeedAddress, domainRegistry.getPriceFeedContractAddress());
  }

  function test_GetMetadataContractAddress() public {
    assertEq(metadataAddress, domainRegistry.getMetadataContractAddress());
  }

  function test_GetTokenIdsCount() public {
    uint initialCount = domainRegistry.getTokenIdsCount();
    string memory plusCode = randomPlusCode();
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    assertEq(initialCount + 1, domainRegistry.getTokenIdsCount());
  }

  function test_GetTokenIdsArray() public {
    string memory plusCode = randomPlusCode();
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    uint256 arrayLength = domainRegistry.getTokenIdsCount();
    // Reverts if start index is more than the end index
    vm.expectRevert(IndexError.selector);
    domainRegistry.getTokenIdsArray(2, 1);
    // Get the full array
    uint256[] memory fullTokenIdsArray = domainRegistry.getTokenIdsArray(0, arrayLength);
    assertEq(arrayLength, fullTokenIdsArray.length);
    assertEq(tokenId, fullTokenIdsArray[arrayLength - 1]);
    // Mint minimum of 10
    vm.startPrank(USER);
    if (domainRegistry.getTokenIdsCount() < 10) {
      for (uint256 i = domainRegistry.getTokenIdsCount(); i < 10; i++) {
        domainRegistry.mint{value: mintCost}(randomPlusCode());
      }
    }
    vm.stopPrank();
    uint256[] memory expectedArray = new uint256[](10);
    for (uint i = 0; i < 10; i++) {
      expectedArray[i] = domainRegistry.tokenIds(i);
    }
    // Get first 10 of the array
    uint256[] memory partOwnersArray = domainRegistry.getTokenIdsArray(0, 9);
    assertEq(10, partOwnersArray.length);
    assertEq(expectedArray[9], partOwnersArray[9]);
    assertEq(expectedArray[0], partOwnersArray[0]);
    assertEq(expectedArray[5], partOwnersArray[5]);
    // Get index 6 to 7 of the array
    uint256[] memory twoTokenIdsArray = domainRegistry.getTokenIdsArray(5, 6);
    assertEq(2, twoTokenIdsArray.length);
    assertEq(expectedArray[5], twoTokenIdsArray[0]);
    assertEq(expectedArray[6], twoTokenIdsArray[1]);
    // Get a single index of the array
    uint256[] memory singleIndexTokenIdsArray = domainRegistry.getTokenIdsArray(8, 8);
    assertEq(1, singleIndexTokenIdsArray.length);
    assertEq(expectedArray[8], singleIndexTokenIdsArray[0]);
    // Get a last index of the array
    uint256[] memory lastIndexTokenIdsArray = domainRegistry.getTokenIdsArray(9, 9);
    assertEq(1, lastIndexTokenIdsArray.length);
    assertEq(expectedArray[9], lastIndexTokenIdsArray[0]);
  }

  function test_GetPlusCodesArray() public {
    string memory plusCode = randomPlusCode();
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    uint256 arrayLength = domainRegistry.getTokenIdsCount();
    // Reverts if start index is more than the end index
    vm.expectRevert(IndexError.selector);
    domainRegistry.getPlusCodesArray(2, 1);
    // Get the full array
    string[] memory fullPlusCodesArray = domainRegistry.getPlusCodesArray(0, arrayLength);
    assertEq(arrayLength, fullPlusCodesArray.length);
    assertEq(plusCode, fullPlusCodesArray[arrayLength - 1]);
    // Mint minimum of 10
    vm.startPrank(USER);
    if (domainRegistry.getTokenIdsCount() < 10) {
      for (uint256 i = domainRegistry.getTokenIdsCount(); i < 10; i++) {
        domainRegistry.mint{value: mintCost}(randomPlusCode());
      }
    }
    vm.stopPrank();
    string[] memory expectedArray = new string[](10);
    for (uint i = 0; i < 10; i++) {
      expectedArray[i] = domainRegistry.s_tokenIdToPlusCode(domainRegistry.tokenIds(i));
    }
    // Get first 10 of the array
    string[] memory partOwnersArray = domainRegistry.getPlusCodesArray(0, 9);
    assertEq(10, partOwnersArray.length);
    assertEq(expectedArray[9], partOwnersArray[9]);
    assertEq(expectedArray[0], partOwnersArray[0]);
    assertEq(expectedArray[5], partOwnersArray[5]);
    // Get index 6 to 7 of the array
    string[] memory twoPlusCodesArray = domainRegistry.getPlusCodesArray(5, 6);
    assertEq(2, twoPlusCodesArray.length);
    assertEq(expectedArray[5], twoPlusCodesArray[0]);
    assertEq(expectedArray[6], twoPlusCodesArray[1]);
    // Get a single index of the array
    string[] memory singleIndexPlusCodesArray = domainRegistry.getPlusCodesArray(8, 8);
    assertEq(1, singleIndexPlusCodesArray.length);
    assertEq(expectedArray[8], singleIndexPlusCodesArray[0]);
    // Get a last index of the array
    string[] memory lastIndexPlusCodesArray = domainRegistry.getPlusCodesArray(9, 9);
    assertEq(1, lastIndexPlusCodesArray.length);
    assertEq(expectedArray[9], lastIndexPlusCodesArray[0]);
  }

  function test_GetOwnersArray() public {
    string memory plusCode = randomPlusCode();
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    address owner = domainRegistry.ownerOf(tokenId);
    uint256 arrayLength = domainRegistry.getTokenIdsCount();
    // Reverts if start index is more than the end index
    vm.expectRevert(IndexError.selector);
    domainRegistry.getOwnersArray(2, 1);
    // Get the full array
    address[] memory fullOwnersArray = domainRegistry.getOwnersArray(0, arrayLength);
    assertEq(arrayLength, fullOwnersArray.length);
    // Last owner matches the last mint owner
    assertEq(owner, fullOwnersArray[arrayLength - 1]);
    // Mint minimum of 10
    vm.startPrank(USER);
    if (domainRegistry.getTokenIdsCount() < 10) {
      for (uint256 i = domainRegistry.getTokenIdsCount(); i < 10; i++) {
        domainRegistry.mint{value: mintCost}(randomPlusCode());
      }
    }
    vm.stopPrank();
    address[] memory expectedArray = new address[](10);
    for (uint i = 0; i < 10; i++) {
      expectedArray[i] = domainRegistry.ownerOf(domainRegistry.tokenIds(i));
    }
    // Get first 10 of the array
    address[] memory partOwnersArray = domainRegistry.getOwnersArray(0, 9);
    assertEq(10, partOwnersArray.length);
    assertEq(expectedArray[9], partOwnersArray[9]);
    assertEq(expectedArray[0], partOwnersArray[0]);
    assertEq(expectedArray[5], partOwnersArray[5]);
    // Get index 6 to 7 of the array
    address[] memory twoOwnersArray = domainRegistry.getOwnersArray(5, 6);
    assertEq(2, twoOwnersArray.length);
    assertEq(expectedArray[5], twoOwnersArray[0]);
    assertEq(expectedArray[6], twoOwnersArray[1]);
    // Get a single index of the array
    address[] memory singleIndexOwnersArray = domainRegistry.getOwnersArray(8, 8);
    assertEq(1, singleIndexOwnersArray.length);
    assertEq(expectedArray[8], singleIndexOwnersArray[0]);
    // Get a last index of the array
    address[] memory lastIndexOwnersArray = domainRegistry.getOwnersArray(9, 9);
    assertEq(1, lastIndexOwnersArray.length);
    assertEq(expectedArray[9], lastIndexOwnersArray[0]);
  }

  function test_GetUsersArray() public {
    string memory plusCode = randomPlusCode();
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    address owner = domainRegistry.ownerOf(tokenId);
    uint256 arrayLength = domainRegistry.getTokenIdsCount();
    // Reverts if start index is more than the end index
    vm.expectRevert(IndexError.selector);
    domainRegistry.getUsersArray(2, 1);
    // Get the full array
    address[] memory fullUsersArray = domainRegistry.getUsersArray(0, arrayLength);
    assertEq(arrayLength, fullUsersArray.length);
    // Last owner matches the last mint owner
    assertEq(owner, fullUsersArray[arrayLength - 1]);
    // Mint minimum of 10
    vm.startPrank(USER);
    if (domainRegistry.getTokenIdsCount() < 10) {
      for (uint256 i = domainRegistry.getTokenIdsCount(); i < 10; i++) {
        domainRegistry.mint{value: mintCost}(randomPlusCode());
      }
    }
    vm.stopPrank();
    address[] memory expectedArray = new address[](10);
    for (uint i = 0; i < 10; i++) {
      expectedArray[i] = domainRegistry.ownerOf(domainRegistry.tokenIds(i));
    }
    // Get first 10 of the array
    address[] memory partUsersArray = domainRegistry.getUsersArray(0, 9);
    assertEq(10, partUsersArray.length);
    assertEq(expectedArray[9], partUsersArray[9]);
    assertEq(expectedArray[0], partUsersArray[0]);
    assertEq(expectedArray[5], partUsersArray[5]);
    // Get index 6 to 7 of the array
    address[] memory twoUsersArray = domainRegistry.getUsersArray(5, 6);
    assertEq(2, twoUsersArray.length);
    assertEq(expectedArray[5], twoUsersArray[0]);
    assertEq(expectedArray[6], twoUsersArray[1]);
    // Get a single index of the array
    address[] memory singleIndexUsersArray = domainRegistry.getUsersArray(8, 8);
    assertEq(1, singleIndexUsersArray.length);
    assertEq(expectedArray[8], singleIndexUsersArray[0]);
    // Get a last index of the array
    address[] memory lastIndexUsersArray = domainRegistry.getUsersArray(9, 9);
    assertEq(1, lastIndexUsersArray.length);
    assertEq(expectedArray[9], lastIndexUsersArray[0]);
  }

  function test_UpdatePriceFeedContract() public {
    vm.startPrank(DEPLOYER);
    // Deploy a new price feed contract
    MockV3Aggregator newPriceFeed = new MockV3Aggregator(0, 1 * 18);
    address newPriceFeedAddress = address(newPriceFeed);
    console.log("New Price Feed", newPriceFeedAddress);
    // Update to a new price feed contract
    assertEq(usdPriceFeedAddress, domainRegistry.getPriceFeedContractAddress());
    vm.stopPrank();
    // Only contract owner can update the price feed contract
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
    domainRegistry.updatePriceFeedContract(newPriceFeedAddress);
    vm.stopPrank();
    // // Update the price feed contract address in the domain registry
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit IPriceFeedUpdate(newPriceFeedAddress);
    domainRegistry.updatePriceFeedContract(newPriceFeedAddress);
    assertEq(newPriceFeedAddress, domainRegistry.getPriceFeedContractAddress());
    // Set the price feed contract address back to initial address.
    vm.expectEmit(domainRegistryAddress);
    emit IPriceFeedUpdate(usdPriceFeedAddress);
    domainRegistry.updatePriceFeedContract(usdPriceFeedAddress);
    vm.stopPrank();
  }

  function test_UpdateMetadataContract() public {
    vm.startPrank(DEPLOYER);
    // Deploy a new metadata contract
    Metadata newMetadata = new Metadata();
    address newMetadataAddress = address(newMetadata);
    assertEq(metadataAddress, domainRegistry.getMetadataContractAddress());
    vm.stopPrank();
    // Only contract owner can update the metadatacontract
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
    domainRegistry.updateMetadataContract(newMetadataAddress);
    vm.stopPrank();
    // Update the metadata contract address in the domain registry
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit IMetadataUpdate(newMetadataAddress);
    vm.expectEmit(domainRegistryAddress);
    emit BatchMetadataUpdate(0, domainRegistry.MAX_UINT256());
    domainRegistry.updateMetadataContract(newMetadataAddress);
    assertEq(newMetadataAddress, domainRegistry.getMetadataContractAddress());
    // Cannot call tokenURI before setting the domain registry in metadata contract - reverts
    uint256 testTokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    vm.expectRevert(DomainRegistryOnly.selector);
    domainRegistry.tokenURI(testTokenId);
    // Set the domain registry address in the metadata contract
    newMetadata.setDomainRegistry(domainRegistryAddress);
    // Cannot set domain registry address twice - reverts
    vm.expectRevert(DomainRegistryAlreadySet.selector);
    newMetadata.setDomainRegistry(domainRegistryAddress);
    // Reverts if arrays are not set in metadata contract
    vm.expectRevert();
    domainRegistry.tokenURI(testTokenId);
    // Set the arrays in metadata contract
    string[] memory attributeArray = metadata.getAttributeStringArray();
    string[] memory svgArray = metadata.getSvgStringArray();
    vm.expectEmit(newMetadataAddress);
    emit AttributeStringsSet();
    newMetadata.setAttributeStringArray(attributeArray);
    vm.expectEmit(newMetadataAddress);
    emit SvgStringsSet();
    newMetadata.setSvgStringArray(svgArray);
    string memory tokenURI = domainRegistry.tokenURI(testTokenId);
    assertTrue(uint256(keccak256(abi.encodePacked(tokenURI))) != uint256(keccak256(abi.encodePacked(""))));
    // Set the metadata contract address back to initial address.
    vm.expectEmit(domainRegistryAddress);
    emit IMetadataUpdate(metadataAddress);
    vm.expectEmit(domainRegistryAddress);
    emit BatchMetadataUpdate(0, domainRegistry.MAX_UINT256());
    domainRegistry.updateMetadataContract(metadataAddress);
    vm.stopPrank();
  }

  function test_SetContractURI() public {
    // Get Contract URI
    string memory contractURI = domainRegistry.contractURI();
    string memory newContractURI = "Test_Contract_URI";
    // Reverts if caller is not the owner
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
    domainRegistry.setContractURI(newContractURI);
    vm.stopPrank();
    // Set a new contractURI - emits event
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit ContractURIUpdated();
    domainRegistry.setContractURI(newContractURI);
    assertEq(newContractURI, domainRegistry.contractURI());
    // Set contract URI back to initial value
    domainRegistry.setContractURI(contractURI);
    vm.stopPrank();
  }

  function test_TokenURI() public {
    uint256 testTokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    // Returns On-chain Metadata
    vm.startPrank(DEPLOYER);
    string memory tokenURI = domainRegistry.tokenURI(testTokenId);
    assertTrue(tokenURI.includes("data:application/json;base64,"));
    // Set the metadata contract address to Zero address.
    vm.expectEmit(domainRegistryAddress);
    emit IMetadataUpdate(zeroAddress);
    vm.expectEmit(domainRegistryAddress);
    emit BatchMetadataUpdate(0, domainRegistry.MAX_UINT256());
    domainRegistry.updateMetadataContract(zeroAddress);
    // Returns Full URL only when no metadata contract address is avialable.
    assertEq(domainRegistry.tokenURI(testTokenId), string.concat(baseURL, testPlusCode));
    // Returns Token URI only if Base URI is null
    vm.expectEmit(domainRegistryAddress);
    emit NewBaseURI("");
    domainRegistry.setBaseURI("");
    assertEq(domainRegistry.tokenURI(testTokenId), testPlusCode);
    // Reset base URI to original
    domainRegistry.setBaseURI(baseURL);
    // Set the metadata contract address back to intial address.
    domainRegistry.updateMetadataContract(metadataAddress);
    assertEq(tokenURI, domainRegistry.tokenURI(testTokenId));
    vm.stopPrank();
  }

  function test_Receive() public {
    address sender = makeAddr("sender");
    uint256 amount = 1e18;
    vm.deal(sender, STARTING_USER_BALANCE);
    vm.startPrank(sender);
    vm.expectEmit(domainRegistryAddress);
    emit Received(sender, amount);
    payable(domainRegistryAddress).transfer(amount);
    vm.stopPrank();
  }

  function test_Fallback() public {
    address sender = makeAddr("sender");
    uint256 amount = 1e18;
    vm.deal(sender, STARTING_USER_BALANCE);
    vm.startPrank(sender);
    vm.expectEmit(domainRegistryAddress);
    emit Received(sender, amount);
    (bool success, ) = domainRegistryAddress.call{value: amount}(abi.encodeWithSignature("doesNotExist()"));
    assertTrue(success);
    vm.stopPrank();
  }

  function test_SetNewFeePercent() public {
    // Test fee percentage is correct as per set value
    assertEq(feePercent, domainRegistry.s_feePercent()); // original percentage - 100 is 1%

    // Only owner can update
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
    domainRegistry.setNewFeePercent(1);
    vm.stopPrank();

    vm.startPrank(DEPLOYER);

    // Set the fee percentage to more than 100%, sets to 100% max - emits events
    uint256 oneHundredPercent = 10000;
    uint256 overPercentage = 10001;
    vm.expectEmit(domainRegistryAddress);
    emit FeePercentUpdate(oneHundredPercent);
    domainRegistry.setNewFeePercent(overPercentage);
    assertEq(domainRegistry.s_feePercent(), oneHundredPercent);

    // Set the fee percentage to less than 0.01%, sets to 1% min - emits events
    uint256 onePercent = 1;
    uint256 underPercentage = 0;
    vm.expectEmit(domainRegistryAddress);
    emit FeePercentUpdate(onePercent);
    domainRegistry.setNewFeePercent(underPercentage);
    assertEq(domainRegistry.s_feePercent(), onePercent);

    // Set the fee percentage to all of 1 to 100% - emits events
    for (uint i = 1; i <= 100; i++) {
      vm.expectEmit(domainRegistryAddress);
      emit FeePercentUpdate(i * 100);
      domainRegistry.setNewFeePercent(i * 100);
      // Stored fee percent now matches new fee percent
      assertEq(domainRegistry.s_feePercent(), i * 100);
    }

    // Reset fee to original feePercent
    assertEq(feePercent, 100); // 100 is 1%
    vm.expectEmit(domainRegistryAddress);
    emit FeePercentUpdate(feePercent);
    domainRegistry.setNewFeePercent(feePercent);
    assertEq(domainRegistry.s_feePercent(), feePercent);

    vm.stopPrank();
  }

  function test_GetPaymentFee() public {
    uint256 fee;
    uint256 gasPrice = tx.gasprice;
    uint256 amount = 1e18;
    uint256 percentage = domainRegistry.s_feePercent();

    // Test different amounts at current % fee
    for (uint i = 1; i <= 100; i++) {
      amount = (amount / i) + i;
      fee = domainRegistry.getPaymentFee(amount, gasPrice);
      if (fee <= gasPrice) {
        fee = domainRegistry.getPaymentFee(amount, gasPrice);
        assertEq(fee, gasPrice);
      }
      if (fee > gasPrice) {
        assertEq(fee, (amount * percentage) / 10000);
      }
    }

    // Test different amounts at different % fee
    vm.startPrank(DEPLOYER);
    for (uint i = 1; i <= 100; i++) {
      vm.expectEmit(domainRegistryAddress);
      emit FeePercentUpdate(i * 100);
      domainRegistry.setNewFeePercent(i * 100);
      // Stored fee percent now matches new fee percent
      assertEq(domainRegistry.s_feePercent(), i * 100);
      percentage = domainRegistry.s_feePercent();

      // set a new amount to test
      amount = (amount / i) + i;
      fee = domainRegistry.getPaymentFee(amount, gasPrice);
      if (fee <= gasPrice) {
        fee = domainRegistry.getPaymentFee(amount, gasPrice);
        assertEq(fee, gasPrice);
      }
      if (fee > gasPrice) {
        assertEq(fee, (amount * percentage) / 10000);
      }
    }
    vm.stopPrank();
  }

  function test_PayDomain() public {
    uint256 tokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    address payee = domainRegistry.userOf(tokenId);
    address payer = makeAddr("payer");
    vm.deal(payer, STARTING_USER_BALANCE);
    string memory noData = "";
    uint256 msgValue = 1e18 * 10;
    uint256 payeeBalanceBefore;
    uint256 domainBalanceBefore;
    uint256 fee;
    uint256 payment;
    vm.startPrank(payer);
    // Test 10 divisions of 10 ETH + i
    for (uint i = 1; i <= 10; i++) {
      payeeBalanceBefore = payee.balance;
      domainBalanceBefore = domainRegistryAddress.balance;
      msgValue = (msgValue / i) + i;
      fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
      vm.deal(payer, msgValue);
      payment = msgValue - fee;
      vm.expectEmit(domainRegistryAddress);
      emit PayDomain(payee, tokenId, testPlusCode, msgValue, payment, fee, noData);
      assertTrue(domainRegistry.payDomain{value: msgValue}(tokenId, noData));
      assertEq(payeeBalanceBefore + payment, payee.balance);
      assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);
    }
    // Test msgValue less than fee - reverts

    /** msgValue 1 wei less than fee */
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice - 1;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    vm.deal(payer, msgValue);
    vm.expectRevert(abi.encodeWithSelector(NotEnoughWei.selector, fee, msgValue));
    domainRegistry.payDomain{value: msgValue}(tokenId, noData);
    assertEq(payeeBalanceBefore, payee.balance);
    assertEq(domainBalanceBefore, domainRegistryAddress.balance);

    /** msgValue is zero */
    vm.expectRevert(abi.encodeWithSelector(NotEnoughWei.selector, fee, 0));
    domainRegistry.payDomain(tokenId, noData);
    assertEq(payeeBalanceBefore, payee.balance);
    assertEq(domainBalanceBefore, domainRegistryAddress.balance);

    // Test data sent with payment
    string memory data = 'DataTest - Product name or payment reason"';
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayDomain(payee, tokenId, testPlusCode, msgValue, payment, fee, data);
    assertTrue(domainRegistry.payDomain{value: msgValue}(tokenId, data));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    vm.stopPrank();

    // Test fee percentage of 0.01% (s_feePercent 1)
    vm.startPrank(DEPLOYER);
    assertEq(feePercent, domainRegistry.s_feePercent()); // original percentage - 100 is 1%
    vm.expectEmit(domainRegistryAddress);
    emit FeePercentUpdate(1);
    domainRegistry.setNewFeePercent(1);
    assertEq(domainRegistry.s_feePercent(), 1);
    vm.stopPrank();

    vm.startPrank(payer);

    // Test 0.01% with 1ETH payment
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = 1e18;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, (msgValue * domainRegistry.s_feePercent()) / 10000);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayDomain(payee, tokenId, testPlusCode, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payDomain{value: msgValue}(tokenId, noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    // Test 0.01% with tx.gasprice
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, tx.gasprice);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayDomain(payee, tokenId, testPlusCode, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payDomain{value: msgValue}(tokenId, noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    // Test 0.01% where payment calculates to the approx. tx.gasprice when getFeePayment()
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice * 10000;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, tx.gasprice);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayDomain(payee, tokenId, testPlusCode, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payDomain{value: msgValue}(tokenId, noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    vm.stopPrank();

    // Test fee percentage of 100% (s_feePercent 10_000)
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit FeePercentUpdate(10000);
    domainRegistry.setNewFeePercent(10000);
    assertEq(domainRegistry.s_feePercent(), 10000);
    vm.stopPrank();

    vm.startPrank(payer);

    // Test 100% with 1ETH payment
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = 1e18;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, (msgValue * domainRegistry.s_feePercent()) / 10000);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayDomain(payee, tokenId, testPlusCode, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payDomain{value: msgValue}(tokenId, noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    // Test 100% with payment of tx.gasprice
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, tx.gasprice);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayDomain(payee, tokenId, testPlusCode, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payDomain{value: msgValue}(tokenId, noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    vm.stopPrank();

    // Reset fee to original feePercent
    vm.startPrank(DEPLOYER);
    assertEq(feePercent, 100); // 100 is 1%
    vm.expectEmit(domainRegistryAddress);
    emit FeePercentUpdate(feePercent);
    domainRegistry.setNewFeePercent(feePercent);
    assertEq(domainRegistry.s_feePercent(), feePercent);
    vm.stopPrank();
  }

  function test_PayAccount() public {
    address payee = makeAddr("payee");
    address payer = makeAddr("payer");
    vm.deal(payer, STARTING_USER_BALANCE);
    string memory noData = "";
    uint256 msgValue = 1e18 * 10;
    uint256 payeeBalanceBefore;
    uint256 domainBalanceBefore;
    uint256 fee;
    uint256 payment;
    vm.startPrank(payer);
    // Test 10 divisions of 10 ETH + i
    for (uint i = 1; i <= 10; i++) {
      payeeBalanceBefore = payee.balance;
      domainBalanceBefore = domainRegistryAddress.balance;
      msgValue = (msgValue / i) + i;
      fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
      vm.deal(payer, msgValue);
      payment = msgValue - fee;
      vm.expectEmit(domainRegistryAddress);
      emit PayAccount(payee, msgValue, payment, fee, noData);
      assertTrue(domainRegistry.payAccount{value: msgValue}(payable(payee), noData));
      assertEq(payeeBalanceBefore + payment, payee.balance);
      assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);
    }
    // Test msgValue less than fee - reverts

    /** msgValue 1 wei less than fee */
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice - 1;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    vm.deal(payer, msgValue);
    vm.expectRevert(abi.encodeWithSelector(NotEnoughWei.selector, fee, msgValue));
    domainRegistry.payAccount{value: msgValue}(payable(payee), noData);
    assertEq(payeeBalanceBefore, payee.balance);
    assertEq(domainBalanceBefore, domainRegistryAddress.balance);

    /** msgValue is zero */
    vm.expectRevert(abi.encodeWithSelector(NotEnoughWei.selector, fee, 0));
    domainRegistry.payAccount(payable(payee), noData);
    assertEq(payeeBalanceBefore, payee.balance);
    assertEq(domainBalanceBefore, domainRegistryAddress.balance);

    // Test data sent with payment
    string memory data = 'DataTest - Product name or payment reason"';
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayAccount(payee, msgValue, payment, fee, data);
    assertTrue(domainRegistry.payAccount{value: msgValue}(payable(payee), data));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    vm.stopPrank();

    // Test fee percentage of 0.01% (s_feePercent 1)
    vm.startPrank(DEPLOYER);
    assertEq(feePercent, domainRegistry.s_feePercent()); // original percentage - 100 is 1%
    vm.expectEmit(domainRegistryAddress);
    emit FeePercentUpdate(1);
    domainRegistry.setNewFeePercent(1);
    assertEq(domainRegistry.s_feePercent(), 1);
    vm.stopPrank();

    vm.startPrank(payer);

    // Test 0.01% with 1ETH payment
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = 1e18;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, (msgValue * domainRegistry.s_feePercent()) / 10000);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayAccount(payee, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payAccount{value: msgValue}(payable(payee), noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    // Test 0.01% with tx.gasprice
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, tx.gasprice);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayAccount(payee, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payAccount{value: msgValue}(payable(payee), noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    // Test 0.01% where payment calculates to the approx. tx.gasprice when getFeePayment()
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice * 10000;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, tx.gasprice);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayAccount(payee, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payAccount{value: msgValue}(payable(payee), noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    vm.stopPrank();

    // Test fee percentage of 100% (s_feePercent 10_000)
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit FeePercentUpdate(10000);
    domainRegistry.setNewFeePercent(10000);
    assertEq(domainRegistry.s_feePercent(), 10000);
    vm.stopPrank();

    vm.startPrank(payer);

    // Test 100% with 1ETH payment
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = 1e18;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, (msgValue * domainRegistry.s_feePercent()) / 10000);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayAccount(payee, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payAccount{value: msgValue}(payable(payee), noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    // Test 100% with payment of tx.gasprice
    payeeBalanceBefore = payee.balance;
    domainBalanceBefore = domainRegistryAddress.balance;
    msgValue = tx.gasprice;
    fee = domainRegistry.getPaymentFee(msgValue, tx.gasprice);
    assertEq(fee, tx.gasprice);
    vm.deal(payer, msgValue);
    payment = msgValue - fee;
    vm.expectEmit(domainRegistryAddress);
    emit PayAccount(payee, msgValue, payment, fee, noData);
    assertTrue(domainRegistry.payAccount{value: msgValue}(payable(payee), noData));
    assertEq(payeeBalanceBefore + payment, payee.balance);
    assertEq(domainBalanceBefore + fee, domainRegistryAddress.balance);

    vm.stopPrank();

    // Reset fee to original feePercent
    vm.startPrank(DEPLOYER);
    assertEq(feePercent, 100); // 100 is 1%
    vm.expectEmit(domainRegistryAddress);
    emit FeePercentUpdate(feePercent);
    domainRegistry.setNewFeePercent(feePercent);
    assertEq(domainRegistry.s_feePercent(), feePercent);
    vm.stopPrank();
  }

  function test_Withdraw() public {
    address addressTo = makeAddr("addressTo");
    uint256 amount = 1e18;
    // Non owner cannot withdraw
    vm.startPrank(USER);
    payable(domainRegistryAddress).transfer(amount);
    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
    domainRegistry.withdraw(payable(USER), domainRegistryAddress.balance);
    vm.stopPrank();
    // Owner can withdraw
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit Withdraw(addressTo, amount);
    domainRegistry.withdraw(payable(addressTo), amount);
    vm.stopPrank();
  }

  function test_WithdrawErc20() public {
    address addressTo = makeAddr("addressTo");
    uint256 amount = 1e18;
    // Deploy a MockERC20 token
    address mockErcDeployer = makeAddr("mockErcDeployer");
    vm.startPrank(mockErcDeployer);
    MockERC20 mockErc20 = new MockERC20();
    address mockErc20Address = address(mockErc20);
    vm.stopPrank();
    // Send some Mock Token to the domain registry contract;
    vm.startPrank(mockErcDeployer);
    mockErc20.transfer(domainRegistryAddress, amount);
    assertEq(amount, mockErc20.balanceOf(domainRegistryAddress));
    vm.stopPrank();
    // Non owner cannot withdraw ERC20 token
    vm.startPrank(USER);
    vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, USER));
    domainRegistry.withdrawErc20(mockErc20Address, payable(USER), domainRegistryAddress.balance);
    vm.stopPrank();
    // Owner can withdraw ERC20 token to another address
    vm.startPrank(DEPLOYER);
    vm.expectEmit(domainRegistryAddress);
    emit WithdrawERC20(mockErc20Address, addressTo, amount);
    domainRegistry.withdrawErc20(mockErc20Address, payable(addressTo), amount);
    vm.stopPrank();
    assertEq(amount, mockErc20.balanceOf(addressTo));
  }

  function test_Exists() public {
    uint256 nonMintedTokenId = domainRegistry.plusCodeToTokenId(randomPlusCode());
    uint256 testPlusCodeTokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    // Returns false for non existing token
    assertTrue(domainRegistry.exists(nonMintedTokenId) == false);
    // Returns true for existing token
    assertTrue(domainRegistry.exists(testPlusCodeTokenId));
  }

  // Resolver Functions

  function test_Set() public {
    uint256 tokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    // Reset token records to Null
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    domainRegistry.reset(tokenId);
    vm.stopPrank();
    // Assert that records are null
    assertEq(0, domainRegistry.getKeysOf(tokenId).length);
    // Not approved or owner cannot set records
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, address(this), tokenId));
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    // Set records
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit NewKey(tokenId, testKeys[0], testKeys[0]);
    vm.expectEmit(domainRegistryAddress);
    emit Set(tokenId, testKeys[0], testValues[0], testKeys[0], testValues[0]);
    domainRegistry.set(testKeys[0], testValues[0], tokenId);
    vm.stopPrank();
    // Assert that records are set
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    assertEq(keysOf.length, 1);
    assertEq(keysOf[0], testKeys[0]);
    assertEq(valuesOf[0], testValues[0]);
  }

  function test_SetMany() public {
    uint256 tokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    // Reset token records to Null
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    domainRegistry.reset(tokenId);
    vm.stopPrank();
    // Assert that records are null
    assertEq(0, domainRegistry.getKeysOf(tokenId).length);
    // Not approved or owner cannot set records
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, address(this), tokenId));
    domainRegistry.setMany(testKeys, testValues, tokenId);
    // Set records
    vm.startPrank(USER);
    for (uint i = 0; i < testKeys.length; i++) {
      vm.expectEmit(domainRegistryAddress);
      emit NewKey(tokenId, testKeys[i], testKeys[i]);
      vm.expectEmit(domainRegistryAddress);
      emit Set(tokenId, testKeys[i], testValues[i], testKeys[i], testValues[i]);
    }
    domainRegistry.setMany(testKeys, testValues, tokenId);
    vm.stopPrank();
    // Assert that records are set
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    assertEq(keysOf.length, testKeys.length);
    for (uint i = 0; i < keysOf.length; i++) {
      assertEq(keysOf[i], testKeys[i]);
      assertEq(valuesOf[i], testValues[i]);
    }
  }

  function test_SetByHash() public {
    uint256 tokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    // Reset token records to Null
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    domainRegistry.reset(tokenId);
    vm.stopPrank();
    // Assert that records are null
    assertEq(0, domainRegistry.getKeysOf(tokenId).length);
    // Set a hash array of the test keys
    uint256[] memory keyHashes = new uint256[](testKeys.length);
    for (uint i = 0; i < testKeys.length; i++) {
      keyHashes[i] = uint256(keccak256(abi.encodePacked(testKeys[i])));
      // Add key to domain registry if it doesnt already exist
      domainRegistry.addKey(testKeys[i]);
    }
    // Not approved or owner cannot set records
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, address(this), tokenId));
    domainRegistry.setByHash(keyHashes[0], testValues[0], tokenId);
    vm.startPrank(USER);
    // Cannot set by Hash when keys do not already exist
    uint256[] memory nonExistingHashes = new uint256[](2);
    for (uint i = 0; i < 2; i++) {
      nonExistingHashes[i] = uint256(
        keccak256(
          abi.encodePacked(
            randomPlusCode(),
            domainRegistry.tokenIds(domainRegistry.getTokenIdsCount() - 1),
            i,
            nonExistingHashes[i]
          )
        )
      );
    }
    vm.expectRevert("RecordStorage: KEY_NOT_FOUND");
    domainRegistry.setByHash(nonExistingHashes[0], testValues[0], tokenId);
    // Set records
    vm.expectEmit(domainRegistryAddress);
    emit NewKey(tokenId, testKeys[0], testKeys[0]);
    vm.expectEmit(domainRegistryAddress);
    emit Set(tokenId, testKeys[0], testValues[0], testKeys[0], testValues[0]);
    domainRegistry.setByHash(keyHashes[0], testValues[0], tokenId);
    vm.stopPrank();
    // Assert that records are set
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    assertEq(keysOf.length, 1);
    assertEq(keysOf[0], testKeys[0]);
    assertEq(valuesOf[0], testValues[0]);
  }

  function test_SetManyByHash() public {
    uint256 tokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    // Reset token records to Null
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    domainRegistry.reset(tokenId);
    vm.stopPrank();
    // Assert that records are null
    assertEq(0, domainRegistry.getKeysOf(tokenId).length);
    // Set a hash array of the test keys
    uint256[] memory keyHashes = new uint256[](testKeys.length);
    for (uint i = 0; i < testKeys.length; i++) {
      keyHashes[i] = uint256(keccak256(abi.encodePacked(testKeys[i])));
      // Add key to domain registry if it doesnt already exist
      domainRegistry.addKey(testKeys[i]);
    }
    // Not approved or owner cannot set records
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, address(this), tokenId));
    domainRegistry.setManyByHash(keyHashes, testValues, tokenId);
    vm.startPrank(USER);
    // Cannot set by Hash when keys do not already exist
    uint256[] memory nonExistingHashes = new uint256[](2);
    for (uint i = 0; i < 2; i++) {
      nonExistingHashes[i] = uint256(
        keccak256(
          abi.encodePacked(
            randomPlusCode(),
            domainRegistry.tokenIds(domainRegistry.getTokenIdsCount() - 1),
            i,
            nonExistingHashes[i]
          )
        )
      );
    }
    vm.expectRevert("RecordStorage: KEY_NOT_FOUND");
    domainRegistry.setManyByHash(nonExistingHashes, testValues, tokenId);
    // Set records
    for (uint i = 0; i < testKeys.length; i++) {
      vm.expectEmit(domainRegistryAddress);
      emit NewKey(tokenId, testKeys[i], testKeys[i]);
      vm.expectEmit(domainRegistryAddress);
      emit Set(tokenId, testKeys[i], testValues[i], testKeys[i], testValues[i]);
    }
    domainRegistry.setManyByHash(keyHashes, testValues, tokenId);
    vm.stopPrank();
    // Assert that records are set
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    assertEq(keysOf.length, testKeys.length);
    for (uint i = 0; i < keysOf.length; i++) {
      assertEq(keysOf[i], testKeys[i]);
      assertEq(valuesOf[i], testValues[i]);
    }
  }

  function test_Reconfigure() public {
    uint256 tokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    // Set records before reconfiguration
    vm.startPrank(USER);
    for (uint i = 0; i < testKeys.length; i++) {
      vm.expectEmit(domainRegistryAddress);
      emit NewKey(tokenId, testKeys[i], testKeys[i]);
      vm.expectEmit(domainRegistryAddress);
      emit Set(tokenId, testKeys[i], testValues[i], testKeys[i], testValues[i]);
    }
    domainRegistry.setMany(testKeys, testValues, tokenId);
    vm.stopPrank();
    // Assert that records are set
    string[] memory keysOfBefore = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOfBefore = domainRegistry.getMany(keysOfBefore, tokenId);
    assertEq(keysOfBefore.length, testKeys.length);
    for (uint i = 0; i < keysOfBefore.length; i++) {
      assertEq(keysOfBefore[i], testKeys[i]);
      assertEq(valuesOfBefore[i], testValues[i]);
    }
    // Not approved or owner cannot reconfigure records
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, address(this), tokenId));
    domainRegistry.reconfigure(testKeys, testValues, tokenId);
    // Reconfigure with new keys
    vm.startPrank(USER);
    string[] memory nonExistingKeys = new string[](2);
    for (uint i = 0; i < 2; i++) {
      nonExistingKeys[i] = string(
        abi.encodePacked(randomPlusCode(), domainRegistry.tokenIds(domainRegistry.getTokenIdsCount() - 1), i)
      );
    }
    // Set records
    for (uint i = 0; i < nonExistingKeys.length; i++) {
      vm.expectEmit(domainRegistryAddress);
      emit NewKey(tokenId, nonExistingKeys[i], nonExistingKeys[i]);
      vm.expectEmit(domainRegistryAddress);
      emit Set(tokenId, nonExistingKeys[i], testValues[i], nonExistingKeys[i], testValues[i]);
    }
    domainRegistry.reconfigure(nonExistingKeys, testValues, tokenId);
    // Assert that records are set
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    assertEq(keysOf.length, nonExistingKeys.length);
    for (uint i = 0; i < keysOf.length; i++) {
      assertEq(keysOf[i], nonExistingKeys[i]);
      assertEq(valuesOf[i], testValues[i]);
    }
    vm.stopPrank();
  }

  function test_Reset() public {
    uint256 tokenId = domainRegistry.plusCodeToTokenId(testPlusCode);
    // Set records before testing reset
    vm.startPrank(USER);
    for (uint i = 0; i < testKeys.length; i++) {
      vm.expectEmit(domainRegistryAddress);
      emit NewKey(tokenId, testKeys[i], testKeys[i]);
      vm.expectEmit(domainRegistryAddress);
      emit Set(tokenId, testKeys[i], testValues[i], testKeys[i], testValues[i]);
    }
    domainRegistry.setMany(testKeys, testValues, tokenId);
    // Assert that records are set
    string[] memory keysOfBefore = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOfBefore = domainRegistry.getMany(keysOfBefore, tokenId);
    assertEq(keysOfBefore.length, testKeys.length);
    for (uint i = 0; i < keysOfBefore.length; i++) {
      assertEq(keysOfBefore[i], testKeys[i]);
      assertEq(valuesOfBefore[i], testValues[i]);
    }
    vm.stopPrank();
    // Not approved or owner cannot reset records
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, address(this), tokenId));
    domainRegistry.reset(tokenId);
    // Reset token records to Null
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    domainRegistry.reset(tokenId);
    vm.stopPrank();
    // Assert that records are null
    assertEq(0, domainRegistry.getKeysOf(tokenId).length);
  }

  // Resolver Get functions

  function test_GetRecordFunctions() public {
    string memory plusCode = randomPlusCode();
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Mint new random domain with records - emits events
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(zeroAddress, USER, tokenId);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    for (uint i = 0; i < testKeys.length; i++) {
      vm.expectEmit(domainRegistryAddress);
      emit NewKey(tokenId, testKeys[i], testKeys[i]);
      vm.expectEmit(domainRegistryAddress);
      emit Set(tokenId, testKeys[i], testValues[i], testKeys[i], testValues[i]);
    }
    domainRegistry.mintWithRecords{value: mintCost}(plusCode, testKeys, testValues);
    vm.stopPrank();
    // token exist - assert
    assertTrue(domainRegistry.exists(tokenId));
    // Assert Keys and values from various getter functions
    // Test getKeysOf()
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    // Test getMany()
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    for (uint i = 0; i < keysOf.length; i++) {
      assertEq(keysOf[i], testKeys[i]);
      assertEq(valuesOf[i], testValues[i]);
    }
    // Create test key hashes
    uint256[] memory testKeyHashes = new uint256[](testKeys.length);
    for (uint i = 0; i < testKeys.length; i++) {
      testKeyHashes[i] = uint256(keccak256(abi.encodePacked(testKeys[i])));
    }
    // Test getKeys()
    string[] memory retrievedKeys = domainRegistry.getKeys(testKeyHashes);
    for (uint i = 0; i < testKeys.length; i++) {
      assertEq(testKeys[i], retrievedKeys[i]);
    }
    // Test getKey()
    for (uint i = 0; i < testKeys.length; i++) {
      assertEq(testKeys[i], domainRegistry.getKey(testKeyHashes[i]));
    }
    // Test get()
    for (uint i = 0; i < testKeys.length; i++) {
      assertEq(testValues[i], domainRegistry.get(testKeys[i], tokenId));
    }
    // Test getByHash()
    string[] memory getByHashKeys = new string[](testKeys.length);
    string[] memory getByHashValues = new string[](testKeys.length);
    for (uint i = 0; i < testKeys.length; i++) {
      (getByHashKeys[i], getByHashValues[i]) = domainRegistry.getByHash(testKeyHashes[i], tokenId);
    }
    for (uint i = 0; i < testKeys.length; i++) {
      assertEq(testKeys[i], getByHashKeys[i]);
      assertEq(testValues[i], getByHashValues[i]);
    }
    // Test getManyByHash()
    string[] memory getManyByHashKeys = new string[](testKeys.length);
    string[] memory getManyByHashValues = new string[](testKeys.length);
    for (uint i = 0; i < testKeys.length; i++) {
      (getManyByHashKeys, getManyByHashValues) = domainRegistry.getManyByHash(testKeyHashes, tokenId);
    }
    for (uint i = 0; i < testKeys.length; i++) {
      assertEq(testKeys[i], getManyByHashKeys[i]);
      assertEq(testValues[i], getManyByHashValues[i]);
    }
  }

  function test_AddKey() public {
    // Create new keys and hashes
    string memory nonExistingKey = string(
      abi.encodePacked(randomPlusCode(), domainRegistry.tokenIds(domainRegistry.getTokenIdsCount() - 1))
    );
    uint256 nonExistingKeyHash = uint256(keccak256(abi.encodePacked(nonExistingKey)));
    assertEq("", domainRegistry.getKey(nonExistingKeyHash));
    domainRegistry.addKey(nonExistingKey);
    assertEq(nonExistingKey, domainRegistry.getKey(nonExistingKeyHash));
  }

  // NFT Rentals

  function test_SetUser_UserOf_UserExpires() public {
    string memory plusCode = randomPlusCode();
    address renter = makeAddr("renter");
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    uint64 expires = uint64(block.timestamp + 1 minutes);
    // Mint new random domain
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    vm.stopPrank();
    // Assert user expiry is Max uint256 when the user is the owner
    assertEq(USER, domainRegistry.userOf(tokenId));
    assertEq(type(uint256).max, domainRegistry.userExpires(tokenId));
    // Not approved or owner cannot set user
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, address(this), tokenId));
    domainRegistry.setUser(tokenId, renter, expires);
    // Set user to the renter address
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit UpdateUser(tokenId, renter, expires);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    domainRegistry.setUser(tokenId, renter, expires);
    vm.stopPrank();
    // Assert that the user is the renter
    assertEq(renter, domainRegistry.userOf(tokenId));
    // Assert user expiry is correctly set
    assertEq(expires, domainRegistry.userExpires(tokenId));
    // Move block timestamp to more than the expiry
    vm.warp(expires + 1 seconds);
    assertTrue(block.timestamp > expires);
    // Assert that the user returns to the owner after expiry
    assertEq(USER, domainRegistry.userOf(tokenId));
  }

  function test_IsUserOrApproved() public {
    string memory plusCode = randomPlusCode();
    address approvedUser = makeAddr("approvedUser");
    address unapprovedUser = makeAddr("unapprovedUser");
    address renter = makeAddr("renter");
    uint64 expires = uint64(block.timestamp + 1 minutes);
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Reverts if token does not exist
    vm.expectRevert(abi.encodeWithSelector(ERC721NonexistentToken.selector, tokenId));
    domainRegistry.isUserOrApproved(USER, tokenId);
    // Mint new random domain
    vm.startPrank(USER);
    domainRegistry.mint{value: mintCost}(plusCode);
    // Set approval for approvedUser address - expect emit
    vm.expectEmit(domainRegistryAddress);
    emit Approval(USER, approvedUser, tokenId);
    domainRegistry.approve(approvedUser, tokenId);
    // Assert IsUserOrApproved returns true for the owner
    assertTrue(domainRegistry.isUserOrApproved(USER, tokenId));
    // Assert IsUserOrApproved returns false for the unapprovedUser
    assertTrue(!(domainRegistry.isUserOrApproved(unapprovedUser, tokenId)));
    // Assert IsUserOrApproved returns false for the renter
    assertTrue(!(domainRegistry.isUserOrApproved(renter, tokenId)));
    // Assert IsUserOrApproved returns true for the approvedUser
    assertTrue(domainRegistry.isUserOrApproved(approvedUser, tokenId));
    // Set user to the renter address
    vm.expectEmit(domainRegistryAddress);
    emit UpdateUser(tokenId, renter, expires);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    domainRegistry.setUser(tokenId, renter, expires);
    vm.stopPrank();
    // Assert IsUserOrApproved returns false for the approvedUser
    assertTrue(!(domainRegistry.isUserOrApproved(approvedUser, tokenId)));
    // Assert IsUserOrApproved returns false for the owner
    assertTrue(!(domainRegistry.isUserOrApproved(USER, tokenId)));
    // Assert IsUserOrApproved returns false for the unapprovedUser
    assertTrue(!(domainRegistry.isUserOrApproved(unapprovedUser, tokenId)));
    // Assert IsUserOrApproved returns true for the renter
    assertTrue(domainRegistry.isUserOrApproved(renter, tokenId));
  }

  // // Burning

  function test_Burn() public {
    string memory plusCode = randomPlusCode();
    address approvedUser = makeAddr("approvedUser");
    address unapprovedUser = makeAddr("unapprovedUser");
    address renter = makeAddr("renter");
    uint64 expires = uint64(block.timestamp + 1 minutes);
    uint256 tokenId = domainRegistry.plusCodeToTokenId(plusCode);
    // Reverts if token does not exist
    vm.expectRevert(abi.encodeWithSelector(ERC721NonexistentToken.selector, tokenId));
    domainRegistry.burn(tokenId);
    // Mint new random domain with records
    vm.startPrank(USER);
    domainRegistry.mintWithRecords{value: mintCost}(plusCode, testKeys, testValues);
    // Assert token exists and records exist
    assertTrue(domainRegistry.exists(tokenId));
    string[] memory keysOf = domainRegistry.getKeysOf(tokenId);
    string[] memory valuesOf = domainRegistry.getMany(keysOf, tokenId);
    for (uint i = 0; i < keysOf.length; i++) {
      assertEq(keysOf[i], testKeys[i]);
      assertEq(valuesOf[i], testValues[i]);
    }
    // Assert tokenId added to tokenIds array
    uint256[] memory tokenIdsArrayLastEntry = domainRegistry.getTokenIdsArray(
      domainRegistry.getTokenIdsCount() - 1,
      domainRegistry.getTokenIdsCount() - 1
    );
    assertEq(tokenIdsArrayLastEntry[0], tokenId);
    // Assert plusCode added to s_tokenIdToPlusCode
    assertTrue(keccak256(abi.encode(domainRegistry.s_tokenIdToPlusCode(tokenId))) == keccak256(abi.encode(plusCode)));
    // Set approval for approvedUser address - expect emit
    vm.expectEmit(domainRegistryAddress);
    emit Approval(USER, approvedUser, tokenId);
    domainRegistry.approve(approvedUser, tokenId);
    // Set a token renter (userOf)
    vm.expectEmit(domainRegistryAddress);
    emit UpdateUser(tokenId, renter, expires);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    domainRegistry.setUser(tokenId, renter, expires);
    vm.stopPrank();
    // Assert nonApprovedUser cannot burn token
    vm.startPrank(unapprovedUser);
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, unapprovedUser, tokenId));
    domainRegistry.burn(tokenId);
    vm.stopPrank();
    // Assert renter cannot burn token
    assertEq(renter, domainRegistry.userOf(tokenId));
    vm.startPrank(renter);
    vm.expectRevert(abi.encodeWithSelector(ERC721InsufficientApproval.selector, renter, tokenId));
    domainRegistry.burn(tokenId);
    vm.stopPrank();
    // Assert owner can burn token
    vm.startPrank(USER);
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(USER, address(0), tokenId);
    vm.expectEmit(domainRegistryAddress);
    emit UpdateUser(tokenId, address(0), 0);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    domainRegistry.burn(tokenId);
    // Assert token exists is false
    assertTrue(!(domainRegistry.exists(tokenId)));
    // Assert tokenId removed from tokenIds array
    uint256[] memory tokenIdsArrayAfter = domainRegistry.getTokenIdsArray(0, domainRegistry.getTokenIdsCount());
    bool includesAfter = false;
    for (uint i = 0; i < tokenIdsArrayAfter.length; i++) {
      if (tokenIdsArrayAfter[i] == tokenId) {
        includesAfter = true;
      }
    }
    assertFalse(includesAfter);
    // Assert plusCode removed from s_tokenIdToPlusCode
    assertTrue(keccak256(abi.encode(domainRegistry.s_tokenIdToPlusCode(tokenId))) == keccak256(abi.encode("")));
    // Assert record have been deleted
    string[] memory keysOfAfter = domainRegistry.getKeysOf(tokenId);
    uint256 keysLength = keysOfAfter.length;
    assertEq(keysLength, 0);
    // Expect userOf to revert with 'ERC721NonexistentToken' after burn
    vm.expectRevert(abi.encodeWithSelector(ERC721NonexistentToken.selector, tokenId));
    domainRegistry.userOf(tokenId);
    // Expect 'approvedUser' to revert with 'ERC721NonexistentToken' after burn
    vm.expectRevert(abi.encodeWithSelector(ERC721NonexistentToken.selector, tokenId));
    domainRegistry.isApprovedOrOwner(approvedUser, tokenId);
    // Assert can re-mint token
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(zeroAddress, USER, tokenId);
    vm.expectEmit(domainRegistryAddress);
    emit MetadataUpdate(tokenId);
    domainRegistry.mint{value: mintCost}(plusCode);
    assertTrue(domainRegistry.exists(tokenId));
    // Assert userOf is owner after re-minting
    assertEq(USER, domainRegistry.userOf(tokenId));
    // Assert 'approvedUser' is not approved after re-minting
    assertTrue(!domainRegistry.isApprovedOrOwner(approvedUser, tokenId));
    // Set approval for approvedUser address - expect emit
    vm.expectEmit(domainRegistryAddress);
    emit Approval(USER, approvedUser, tokenId);
    domainRegistry.approve(approvedUser, tokenId);
    vm.stopPrank();
    // Assert approvedUser can burn token
    vm.startPrank(approvedUser);
    vm.expectEmit(domainRegistryAddress);
    emit ResetRecords(tokenId);
    vm.expectEmit(domainRegistryAddress);
    emit Transfer(USER, address(0), tokenId);
    domainRegistry.burn(tokenId);
    vm.stopPrank();
  }
}
