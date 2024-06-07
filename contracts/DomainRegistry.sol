// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {StringUtilsLib} from "./StringUtilsLib.sol";
import "./interfaces/IDomainRegistry.sol";
import "./interfaces/IMetadata.sol";
import "./RecordStorage.sol";
import "./PlusCodes.sol";

// Tangiblink Domain Registry Contract used for minting of plusCode identifiable Domain name NFT's,
// and management of NFT key value pairs e.g. Key: ETH, Value: 0x...

/// @custom:security-contact security@tangiblink.io
contract DomainRegistry is
  IDomainRegistry,
  ERC721,
  ERC721URIStorage,
  ERC721Pausable,
  Ownable,
  ERC721Burnable,
  RecordStorage,
  PlusCodes
{
  using SafeERC20 for IERC20;
  using StringUtilsLib for string;

  // Events
  event RefundOverpayment(address indexed account, uint256 amount);
  event NewBaseURI(string _newBaseURI);
  event IPriceFeedUpdate(address priceFeedContract);
  event IMetadataUpdate(address metadataContract);
  event ContractURIUpdated();
  event FeePercentUpdate(uint256 percent);
  event Received(address indexed account, uint256 amount);
  event Withdraw(address indexed addressTo, uint256 amount);
  event WithdrawERC20(address indexed token, address indexed addressTo, uint256 amount);
  event PayAccount(address indexed addressTo, uint256 amount, uint256 paid, uint256 fee, string data);
  event PayDomain(
    address indexed addressTo,
    uint256 indexed tokenId,
    string plusCode,
    uint256 amount,
    uint256 paid,
    uint256 fee,
    string data
  );

  // Custom Errors List
  error InvalidUSDWeiPrice(int256 _usdWei);
  error NotEnoughWei(uint256 _requires, uint256 _provided);
  error EmptyValue();
  error LowBalance();
  error InvalidPlusCode(string code);
  error IndexError();

  // Storage
  string internal s_contractURI;
  string public s_baseURI;
  IMetadata internal s_metadata;
  uint256 public s_mintCostUsd;
  uint256 public s_feePercent; // 10_000 = 100%
  AggregatorV3Interface internal MATIC_USD_FEED;
  uint256[] public tokenIds;
  uint256 public constant MAX_UINT256 = type(uint256).max;
  struct UserInfo {
    address user; // address of user role
    uint64 expires; // unix timestamp, user expires
  }
  mapping(uint256 => UserInfo) internal _users; // Mapping token ID to UserInfo struct object
  mapping(uint256 => string) public s_tokenIdToPlusCode;

  constructor(
    string memory baseURI,
    address metadata,
    uint256 mintCostUsd,
    uint256 feePercent,
    address maticUsdFeed
  ) ERC721("Tangiblink Domains", "TD") Ownable(_msgSender()) {
    s_baseURI = baseURI;
    s_metadata = IMetadata(metadata);
    s_mintCostUsd = mintCostUsd;
    s_feePercent = feePercent;
    MATIC_USD_FEED = AggregatorV3Interface(maticUsdFeed);
  }

  // Modifiers
  /**
   * @notice Modifier - Reverts if msgSender() is not the Owner or Approved to use the token
   * @param tokenId uint256 ID of the token
   */
  modifier onlyApprovedOrOwner(uint256 tokenId) {
    _checkAuthorized(_ownerOf(tokenId), _msgSender(), tokenId);
    _;
  }

  /**
   * @notice Modifier - Reverts if msgSender() is not the Current User (or Approved, if the Current User is the token owner)
   * @param tokenId uint256 ID of the token
   */
  modifier onlyUserOrApproved(uint256 tokenId) {
    if (!isUserOrApproved(_msgSender(), tokenId)) {
      revert ERC721InsufficientApproval(_msgSender(), tokenId);
    }
    _;
  }

  /**
   * @notice Modifier - Reverts for underpayment and refunds overpayment.
   */
  modifier payment() {
    uint256 price = checkPrice();
    if (msg.value < price) {
      revert NotEnoughWei(price, msg.value);
    }
    if (msg.value > price) {
      uint256 refundAmount = msg.value - price;
      payable(_msgSender()).transfer(refundAmount);
      emit RefundOverpayment(_msgSender(), refundAmount);
    }
    _;
  }

  // Emergency functions

  function pause() public override onlyOwner {
    _pause();
  }

  function unpause() public override onlyOwner {
    _unpause();
  }

  // Transferring

  /**
   * @dev Transfer domain ownership without resetting domain records.
   * @param to address of new domain owner
   * @param tokenId uint256 ID of the token to be transferred
   */
  function setOwner(address to, uint256 tokenId) external override onlyApprovedOrOwner(tokenId) {
    _transfer(ownerOf(tokenId), to, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override(ERC721, IERC721) onlyApprovedOrOwner(tokenId) {
    _reset(tokenId);
    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override(ERC721, IERC721) onlyApprovedOrOwner(tokenId) {
    _reset(tokenId);
    _safeTransfer(from, to, tokenId, data);
  }

  function _update(
    address to,
    uint256 tokenId,
    address auth
  ) internal override(ERC721, ERC721Pausable) returns (address) {
    address from = super._update(to, tokenId, auth);
    // Ensures that NFT rentals mapping is reset
    if (from != to && _users[tokenId].user != address(0)) {
      delete _users[tokenId];
      emit UpdateUser(tokenId, address(0), 0);
      emit MetadataUpdate(tokenId);
    }
    return from;
  }

  // Ownership

  /**
   * @dev Returns whether the given spender can transfer a given token ID.
   * @param spender address of the spender to query
   * @param tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   * is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(address spender, uint256 tokenId) external view override returns (bool) {
    address owner = _requireOwned(tokenId);
    return _isAuthorized(owner, spender, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return interfaceId == type(IERC4907).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @notice Initiate the minting of an individual plusCode.
   * @param plusCode - The google Plus Code for the Domain name location.
   */

  function mint(string memory plusCode) external payable override whenNotPaused payment {
    string memory _plusCode = checkCode(plusCode);
    if (bytes(_plusCode).length == 0) {
      revert InvalidPlusCode(plusCode);
    }
    uint256 tokenId = plusCodeToTokenId(_plusCode);
    _safeMint(_msgSender(), tokenId);
    tokenIds.push(tokenId);
    s_tokenIdToPlusCode[tokenId] = _plusCode;
    _setTokenURI(tokenId, _plusCode);
  }

  /**
   * @dev mints token with records
   * @param plusCode - The google Plus Code for the Domain name location.
   * @param keys New record keys
   * @param values New record values
   */
  function mintWithRecords(
    string calldata plusCode,
    string[] calldata keys,
    string[] calldata values
  ) external payable override whenNotPaused payment {
    string memory _plusCode = checkCode(plusCode);
    if (bytes(_plusCode).length == 0) {
      revert InvalidPlusCode(plusCode);
    }
    uint256 tokenId = plusCodeToTokenId(_plusCode);
    _safeMint(_msgSender(), tokenId);
    tokenIds.push(tokenId);
    s_tokenIdToPlusCode[tokenId] = _plusCode;
    _setTokenURI(tokenId, _plusCode);
    _setMany(keys, values, tokenId);
  }

  /**
   * @notice Gets the price from the latest round data of Chainlink price feeds
   * @return usdPerWei The amount of USD in per unit of MATIC in wei.
   */
  function getFeedData() public view override returns (int256) {
    (, int256 usdPerWei, , , ) = MATIC_USD_FEED.latestRoundData();
    if (usdPerWei <= 0) {
      revert InvalidUSDWeiPrice(usdPerWei);
    }
    return usdPerWei;
  }

  /**
   * @notice Checks the price of minting a domain
   * @return maticWei The amount of MATIC in wei equivalent to the USD cost.
   */
  function checkPrice() public view override returns (uint256) {
    uint256 usdPerWei = uint(getFeedData());
    uint256 maticWei = ((1e18 / usdPerWei) * s_mintCostUsd) / 1e10;
    return maticWei;
  }

  /**
   * @notice Converts plusCode name string to a unique uint256 for use as Token ID.
   * @param plusCode - The google Plus Code for the Domain name location.
   */
  function plusCodeToTokenId(string memory plusCode) public pure override returns (uint256) {
    return uint256(keccak256(abi.encodePacked(plusCode)));
  }

  /**
   * @notice Set a new Base URI for concatenation with Token ID to form the full Token URI.
   * @param _newBaseURI - The first fixed part of the full Token URI.
   */
  function setBaseURI(string memory _newBaseURI) public override onlyOwner {
    s_baseURI = _newBaseURI;
    emit NewBaseURI(_newBaseURI);
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenURI`.
   */
  function _baseURI() internal view override(ERC721) returns (string memory) {
    return s_baseURI;
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenURI`.
   */
  function getBaseURI() public view override returns (string memory) {
    return s_baseURI;
  }

  /**
   * @notice Returns the Plus Code for the given token ID
   * @param tokenId uint256 ID of the token
   */
  function getPlusCode(uint256 tokenId) public view override returns (string memory) {
    return s_tokenIdToPlusCode[tokenId];
  }

  /**
   * @notice Getter function for retrieving the Price Feed contract address
   */
  function getPriceFeedContractAddress() public view override returns (address) {
    return address(MATIC_USD_FEED);
  }

  /**
   * @notice Getter function for retrieving the Metadata contract address
   */
  function getMetadataContractAddress() public view override returns (address) {
    return address(s_metadata);
  }

  /**
   * @notice Gets the number of minted tokenIds
   */
  function getTokenIdsCount() public view override returns (uint256 count) {
    return tokenIds.length;
  }

  /**
   * @notice Returns the array of token Ids stored in the tokenIds array
   */
  function getTokenIdsArray(uint256 start, uint256 finish) public view override returns (uint256[] memory) {
    uint256 end = finish + 1;
    if (end > tokenIds.length) end = tokenIds.length;
    if (start >= end) revert IndexError();
    uint256[] memory tokenIdsArray = new uint256[](end - start);
    for (uint256 i = 0; i < end - start; i++) {
      tokenIdsArray[i] = tokenIds[i + start];
    }
    return tokenIdsArray;
  }

  /**
   * @notice Returns an array of Plus Codes stored in the s_tokenIdToPlusCode mapping
   */
  function getPlusCodesArray(uint256 start, uint256 finish) public view override returns (string[] memory) {
    uint256 end = finish + 1;
    if (end > tokenIds.length) end = tokenIds.length;
    if (start >= end) revert IndexError();
    string[] memory plusCodesArray = new string[](end - start);
    for (uint256 i = 0; i < end - start; i++) {
      plusCodesArray[i] = s_tokenIdToPlusCode[tokenIds[i + start]];
    }
    return plusCodesArray;
  }

  /**
   * @notice Returns an array of token owners in the order of the tokenIds array
   */
  function getOwnersArray(uint256 start, uint256 finish) public view override returns (address[] memory) {
    uint256 end = finish + 1;
    if (end > tokenIds.length) end = tokenIds.length;
    if (start >= end) revert IndexError();
    address[] memory ownersArray = new address[](end - start);
    for (uint256 i = 0; i < end - start; i++) {
      ownersArray[i] = ownerOf(tokenIds[i + start]);
    }
    return ownersArray;
  }

  /**
   * @notice Returns an array of token users in the order of the tokenIds array
   */
  function getUsersArray(uint256 start, uint256 finish) public view override returns (address[] memory) {
    uint256 end = finish + 1;
    if (end > tokenIds.length) end = tokenIds.length;
    if (start >= end) revert IndexError();
    address[] memory ownersArray = new address[](end - start);
    for (uint256 i = 0; i < end - start; i++) {
      ownersArray[i] = userOf(tokenIds[i + start]);
    }
    return ownersArray;
  }

  /**
   * @notice Set a new Price Feed address for the Matic to USD conversion.
   * @param _newPriceFeedAddress address of the chainlink price feed.
   */
  function updatePriceFeedContract(address _newPriceFeedAddress) public override onlyOwner {
    MATIC_USD_FEED = AggregatorV3Interface(_newPriceFeedAddress);
    emit IPriceFeedUpdate(_newPriceFeedAddress);
  }

  /**
   * @notice Set a new Contract address for the metadata generating contract.
   * @param _newMetaDataContract address of the metadata generating contract.
   */
  function updateMetadataContract(address _newMetaDataContract) public override onlyOwner {
    s_metadata = IMetadata(_newMetaDataContract);
    emit IMetadataUpdate(_newMetaDataContract);
    emit BatchMetadataUpdate(0, MAX_UINT256);
  }

  /**
   * @notice Set a new Contract URI for OpenSea contract metadata.
   * @param _newContractURI URI of the contract level metadata.
   */
  function setContractURI(string memory _newContractURI) public override onlyOwner {
    s_contractURI = _newContractURI;
    emit ContractURIUpdated();
  }

  /**
   * @notice For OpenSea contract level metadata.
   */
  function contractURI() public view override returns (string memory) {
    return s_contractURI;
  }

  /**@notice Gets the unique token metadata string for market place such as OpenSea
   * @param tokenId uint256 ID of the token
   */
  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    string memory URI = super.tokenURI(tokenId);
    if (address(s_metadata) != address(0)) {
      return s_metadata.getOnChainMetadata(tokenId);
    } else {
      return URI;
    }
  }

  /**
   * @dev This built-in function doesn't require any calldata,
   * it will get called if the data field is empty and the value field is not empty.
   * This allows the smart contract to receive ether just like a regular user account controlled by a private key would.
   */
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  /**
   * @dev Fallback function
   * it will get called if the data field is not empty.
   */
  fallback() external payable {
    emit Received(msg.sender, msg.value);
  }

  /**
   * @notice Set a new payment fee percent.
   * Value of 1 = 0.01%, 100 = 1%, 1000 = 10%, 10000 = 100%
   * maximum fee can be set to 10000 (equivalent to 100%)
   * minimum fee can be set to 1 (equivalent to 0.01%)
   * @param _newFeePercent New fee percent division value.
   */
  function setNewFeePercent(uint _newFeePercent) public override onlyOwner {
    uint maxPercentage = 10000;
    uint minPercentage = 1;
    if (_newFeePercent > maxPercentage) {
      s_feePercent = maxPercentage;
    } else {
      if (_newFeePercent < minPercentage) {
        s_feePercent = minPercentage;
      } else {
        s_feePercent = _newFeePercent;
      }
    }
    emit FeePercentUpdate(s_feePercent);
  }

  /**
   * @notice Gets the fee to deduct from a payment. Minimum of the current tx.gasprice.
   * @param amount The amount of the specified token to be withdrawn.
   * @param gasprice The current gasprice for the transaction.
   * @return fee The fee amount in MATIC wei.
   */
  function getPaymentFee(uint amount, uint gasprice) public view override returns (uint) {
    uint fee = (amount * s_feePercent) / 10000;
    if (fee < gasprice) fee = gasprice;
    return fee;
  }

  /**
   * @notice Allows payment amount of native token to be sent to a domain user.
   * @param tokenId uint256 ID of the token
   * @param data string reason for transfer
   */
  function payDomain(uint256 tokenId, string calldata data) public payable override returns (bool) {
    uint256 fee = getPaymentFee(msg.value, tx.gasprice);
    if (msg.value < fee) {
      revert NotEnoughWei(fee, msg.value);
    }
    uint256 paid = msg.value - fee;
    address addressTo = userOf(tokenId);
    payable(addressTo).transfer(paid);
    emit PayDomain(addressTo, tokenId, s_tokenIdToPlusCode[tokenId], msg.value, paid, fee, data);
    return true;
  }

  /**
   * @notice Allows payment amount of native token to be sent to a domain user.
   * @param addressTo The address to send the token to.
   * @param data string reason for transfer
   */
  function payAccount(address payable addressTo, string calldata data) public payable override returns (bool) {
    uint256 fee = getPaymentFee(msg.value, tx.gasprice);
    if (msg.value < fee) {
      revert NotEnoughWei(fee, msg.value);
    }
    uint256 paid = msg.value - fee;
    addressTo.transfer(paid);
    emit PayAccount(addressTo, msg.value, paid, fee, data);
    return true;
  }

  /**
   * @notice Allows contract owner to withdraw an amount of native token from the contract balance.
   * @param addressTo The address to send the token to.
   * @param amount The amount of the specified token to be withdrawn.
   */
  function withdraw(address payable addressTo, uint amount) public override onlyOwner returns (bool) {
    if (amount > address(this).balance) {
      revert LowBalance();
    }
    addressTo.transfer(amount);
    emit Withdraw(addressTo, amount);
    return true;
  }

  /**
   * @notice Allows contract owner to withdraw an amount of a specified ERC20 token from the contract balance.
   * @param tokenAddress The address of the ERC-20 compliant token.
   * @param addressTo The address to send the token to.
   * @param amount The amount of the specified token to be withdrawn.
   */
  function withdrawErc20(
    address tokenAddress,
    address payable addressTo,
    uint amount
  ) public override onlyOwner returns (bool) {
    IERC20 token = IERC20(tokenAddress);
    if (amount > token.balanceOf(address(this))) {
      revert LowBalance();
    }
    token.safeTransfer(addressTo, amount);
    emit WithdrawERC20(tokenAddress, addressTo, amount);
    return true;
  }

  /**
   * @dev Existence of token.
   * @param tokenId uint256 ID of the token
   */
  function exists(uint256 tokenId) public view override returns (bool) {
    return _ownerOf(tokenId) != address(0);
  }

  // Resolver Functions

  function set(
    string calldata key,
    string calldata value,
    uint256 tokenId
  ) external override whenNotPaused onlyUserOrApproved(tokenId) {
    _set(key, value, tokenId);
  }

  function setMany(
    string[] calldata keys,
    string[] calldata values,
    uint256 tokenId
  ) external override whenNotPaused onlyUserOrApproved(tokenId) {
    _setMany(keys, values, tokenId);
  }

  function setByHash(
    uint256 keyHash,
    string calldata value,
    uint256 tokenId
  ) external override whenNotPaused onlyUserOrApproved(tokenId) {
    _setByHash(keyHash, value, tokenId);
  }

  function setManyByHash(
    uint256[] calldata keyHashes,
    string[] calldata values,
    uint256 tokenId
  ) external override whenNotPaused onlyUserOrApproved(tokenId) {
    _setManyByHash(keyHashes, values, tokenId);
  }

  function reconfigure(
    string[] calldata keys,
    string[] calldata values,
    uint256 tokenId
  ) external override whenNotPaused onlyUserOrApproved(tokenId) {
    _reconfigure(keys, values, tokenId);
  }

  function reset(uint256 tokenId) external override whenNotPaused onlyUserOrApproved(tokenId) {
    _reset(tokenId);
  }

  // NFT Rentals

  /**
   * @notice set the user and expiry of an NFT Rental. Throws if `tokenId` is not valid NFT
   * @dev The zero address indicates there is no user
   * @param tokenId uint256 ID of the token
   * @param user  The new user of the NFT
   * @param expires  UNIX timestamp, The new user could use the NFT before expires
   * */
  function setUser(
    uint256 tokenId,
    address user,
    uint64 expires
  ) public virtual override whenNotPaused onlyApprovedOrOwner(tokenId) {
    UserInfo storage info = _users[tokenId];
    info.user = user;
    info.expires = expires;
    emit UpdateUser(tokenId, user, expires);
    emit MetadataUpdate(tokenId);
  }

  /**
   * @notice Get the user address of an NFT
   * @dev The zero address indicates that there is no user or the user is expired
   * @param tokenId uint256 ID of the token
   * @return The user address for this NFT
   */
  function userOf(uint256 tokenId) public view override returns (address) {
    address owner = _requireOwned(tokenId);
    if (uint256(_users[tokenId].expires) >= block.timestamp) {
      return _users[tokenId].user;
    } else {
      return owner;
    }
  }

  /**
   * @notice Get the user expires of an NFT
   * @dev The max uint256 returned if the current user is the owner of the NFT
   * @param tokenId uint256 ID of the token
   * @return The user expires UNIX Time for this NFT
   */
  function userExpires(uint256 tokenId) public view override returns (uint256) {
    _requireOwned(tokenId);
    uint256 expires = uint256(_users[tokenId].expires);
    if (expires >= block.timestamp) {
      return expires;
    } else {
      return MAX_UINT256;
    }
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   * Requirements:
   * - `tokenId` must exist.
   * @param spender Address of account being queried
   * @param tokenId uint256 ID of the token
   */
  function isUserOrApproved(address spender, uint256 tokenId) public view override returns (bool) {
    address owner = _requireOwned(tokenId);
    if (owner == userOf(tokenId)) {
      return (_isAuthorized(owner, spender, tokenId));
    } else {
      return (spender == userOf(tokenId));
    }
  }

  // Burning

  /**@notice Burns tokens
   * @param tokenId uint256 ID of the token
   */
  function burn(uint256 tokenId) public override(ERC721Burnable, IDomainRegistry) {
    removeFromArrays(tokenId);
    _reset(tokenId);
    super.burn(tokenId);
  }

  /**@notice Deletes tokens from tokenIds array
   * @param tokenId uint256 ID of the token
   */
  function removeFromArrays(uint256 tokenId) internal {
    for (uint i = 0; i < tokenIds.length; i++) {
      if (tokenIds[i] == tokenId) {
        for (i = i; i < tokenIds.length - 1; i++) {
          tokenIds[i] = tokenIds[i + 1];
        }
        tokenIds.pop();
        delete s_tokenIdToPlusCode[tokenId];
        return;
      }
    }
  }
}
