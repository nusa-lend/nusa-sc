// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppOptionsType3} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILendingPool} from "../interfaces/ILendingPool.sol";

contract OAppBorrow is OApp, OAppOptionsType3 {
    // address public lastMessage;
    bytes public lastMessage;

    uint16 public constant SEND = 1;

    address public lendingPool;

    event MessageReceived(uint32 indexed srcEid, address indexed sender, uint64 nonce, address token);
    event SetLendingPool(address lendingPool);

    constructor(address _endpoint, address _owner) OApp(_endpoint, _owner) Ownable(_owner) {}

    function quoteSendString(
        uint32 _dstEid,
        uint256 _amount,
        address _token,
        bytes calldata _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory _message = abi.encode(_amount, _token);
        fee = _quote(_dstEid, _message, combineOptions(_dstEid, SEND, _options), _payInLzToken);
    }

    function sendString(uint32 _dstEid, uint256 _amount, address _token, bytes calldata _options)
        external
        payable
    {
        bytes memory _message = abi.encode(_amount, _token);

        _lzSend(
            _dstEid, _message, combineOptions(_dstEid, SEND, _options), MessagingFee(msg.value, 0), payable(msg.sender)
        );
    }

    // ──────────────────────────────────────────────────────────────────────────────
    // 2. Receive business logic
    //
    // Override _lzReceive to decode the incoming bytes and apply your logic.
    // The base OAppReceiver.lzReceive ensures:
    //   • Only the LayerZero Endpoint can call this method
    //   • The sender is a registered peer (peers[srcEid] == origin.sender)
    // ──────────────────────────────────────────────────────────────────────────────

    /// @notice Invoked by OAppReceiver when EndpointV2.lzReceive is called
    /// @dev   _origin    Metadata (source chain, sender address, nonce)
    /// @dev   _guid      Global unique ID for tracking this message
    /// @param _message   ABI-encoded bytes (the string we sent earlier)
    /// @dev   _executor  Executor address that delivered the message
    /// @dev   _extraData Additional data from the Executor (unused here)
    function _lzReceive(
        Origin calldata _origin,
        bytes32, /*_guid*/
        bytes calldata _message,
        address, /*_executor*/
        bytes calldata /*_extraData*/
    ) internal override {
        (uint256 amount, address token) = abi.decode(_message, (uint256, address));

        lastMessage = _message;

        // Convert bytes32 sender to address
        address sender = address(uint160(uint256(_origin.sender)));

        // 3. (Optional) Trigger further on-chain actions.
        //    e.g., emit an event, mint tokens, call another contract, etc.
        //    emit MessageReceived(_origin.srcEid, _token);

        ILendingPool(lendingPool).borrow(sender, token, amount, block.chainid);

        emit MessageReceived(_origin.srcEid, sender, _origin.nonce, token);
    }

    function setLendingPool(address _lendingPool) public onlyOwner {
        lendingPool = _lendingPool;
        emit SetLendingPool(_lendingPool);
    }
}
