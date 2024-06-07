// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IERC721Errors, IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

/**
 * @dev Required interface of contract Events and Errors for import into Foundry Test contracts.
 */
interface TestEventsAndErrors {
  // Domain Registry Contract Events and Errors
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

  // Domain Registry Keys Events and Errors
  event Set(uint256 indexed tokenId, string indexed keyIndex, string indexed valueIndex, string key, string value);

  event NewKey(uint256 indexed tokenId, string indexed keyIndex, string key);

  event ResetRecords(uint256 indexed tokenId);

  //   Metadata Contract Events and Errors
  event SvgStringsSet();
  event AttributeStringsSet();
  error DomainRegistryOnly();
  error DomainRegistryAlreadySet();

  // ERC4907 Rentable Contract Events and Errors
  // Logged when the user of a token assigns a new user or updates expires
  /**
   * @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
   * The zero address for user indicates that there is no user address
   */
  event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

  //   Pausable Events and Errors
  /**
   * @dev Emitted when the pause is triggered by `account`.
   */
  event Paused(address account);

  /**
   * @dev Emitted when the pause is lifted by `account`.
   */
  event Unpaused(address account);

  //   ERC4906 Events and Errors
  /// @dev This event emits when the metadata of a token is changed.
  /// So that the third-party platforms such as NFT market could
  /// timely update the images and related attributes of the NFT.
  event MetadataUpdate(uint256 _tokenId);

  /// @dev This event emits when the metadata of a range of tokens is changed.
  /// So that the third-party platforms such as NFT market could
  /// timely update the images and related attributes of the NFTs.
  event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

  /**
   * @dev The operation failed because the contract is paused.
   */
  error EnforcedPause();

  /**
   * @dev The operation failed because the contract is not paused.
   */
  error ExpectedPause();

  // OpenZeppelin import Events and Errors
  error StringsInsufficientHexLength(uint256 value, uint256 length);

  /**
   * @dev An operation with an ERC20 token failed.
   */
  error SafeERC20FailedOperation(address token);

  /**
   * @dev Indicates a failed `decreaseAllowance` request.
   */
  error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);
  /**
   * @dev Permit deadline has expired.
   */
  error ERC2612ExpiredSignature(uint256 deadline);

  /**
   * @dev Mismatched signature.
   */
  error ERC2612InvalidSigner(address signer, address owner);

  /**
   * @dev The ETH balance of the account is not enough to perform the operation.
   */
  error AddressInsufficientBalance(address account);

  /**
   * @dev There's no code at `target` (it is not a contract).
   */
  error AddressEmptyCode(address target);

  /**
   * @dev A call to an address target failed. The target may have reverted.
   */
  error FailedInnerCall();

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The caller account is not authorized to perform an operation.
   */
  error OwnableUnauthorizedAccount(address account);

  /**
   * @dev The owner is not a valid owner account. (eg. `address(0)`)
   */
  error OwnableInvalidOwner(address owner);

  // ERC20 Events and Errors
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Standard ERC721 Errors
   * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
   */
  /**
   * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
   * Used in balance queries.
   * @param owner Address of the current owner of a token.
   */
  error ERC721InvalidOwner(address owner);

  /**
   * @dev Indicates a `tokenId` whose `owner` is the zero address.
   * @param tokenId Identifier number of a token.
   */
  error ERC721NonexistentToken(uint256 tokenId);

  /**
   * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   * @param tokenId Identifier number of a token.
   * @param owner Address of the current owner of a token.
   */
  error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

  /**
   * @dev Indicates a failure with the token `sender`. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   */
  error ERC721InvalidSender(address sender);

  /**
   * @dev Indicates a failure with the token `receiver`. Used in transfers.
   * @param receiver Address to which tokens are being transferred.
   */
  error ERC721InvalidReceiver(address receiver);

  /**
   * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
   * @param operator Address that may be allowed to operate on tokens without being their owner.
   * @param tokenId Identifier number of a token.
   */
  error ERC721InsufficientApproval(address operator, uint256 tokenId);

  /**
   * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
   * @param approver Address initiating an approval operation.
   */
  error ERC721InvalidApprover(address approver);

  /**
   * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
   * @param operator Address that may be allowed to operate on tokens without being their owner.
   */
  error ERC721InvalidOperator(address operator);

  //  IERC20Errors
  /**
   * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   * @param balance Current balance for the interacting account.
   * @param needed Minimum amount required to perform a transfer.
   */
  error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

  /**
   * @dev Indicates a failure with the token `sender`. Used in transfers.
   * @param sender Address whose tokens are being transferred.
   */
  error ERC20InvalidSender(address sender);

  /**
   * @dev Indicates a failure with the token `receiver`. Used in transfers.
   * @param receiver Address to which tokens are being transferred.
   */
  error ERC20InvalidReceiver(address receiver);

  /**
   * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
   * @param spender Address that may be allowed to operate on tokens without being their owner.
   * @param allowance Amount of tokens a `spender` is allowed to operate with.
   * @param needed Minimum amount required to perform a transfer.
   */
  error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

  /**
   * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
   * @param approver Address initiating an approval operation.
   */
  error ERC20InvalidApprover(address approver);

  /**
   * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
   * @param spender Address that may be allowed to operate on tokens without being their owner.
   */
  error ERC20InvalidSpender(address spender);
}
