// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/libraries/Errors.sol";
import "src/libraries/ECDSA.sol";
import "src/interfaces/IMintSecurity.sol";
import "src/interfaces/IObeliskNetwork.sol";
import "src/modules/Version.sol";
import "src/modules/Dao.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";

contract MintSecurity is Initializable, Version, Dao, IMintSecurity {
    struct Signature {
        bytes32 r;
        bytes32 vs;
    }

    bytes32 public MINT_MESSAGE_PREFIX;

    uint256 internal quorum;
    address[] internal guardians;

    mapping(address => uint256) internal guardianIndicesOneBased;

    mapping(bytes32 => address) public mintMsgHash;

    address public obeliskNetwork;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _ownerAddr, address _dao, address _obeliskNetwork) public initializer {
        __Version_init(_ownerAddr);
        __Dao_init(_dao);

        MINT_MESSAGE_PREFIX =
            keccak256(abi.encodePacked(keccak256("obelisk.MINT_MESSAGE_PREFIX"), block.chainid, address(this)));
        obeliskNetwork = _obeliskNetwork;
    }

    function getGuardianQuorum() external view returns (uint256) {
        return quorum;
    }

    function setGuardianQuorum(uint256 newValue) external onlyDao {
        _setGuardianQuorum(newValue);
    }

    function _setGuardianQuorum(uint256 newValue) internal {
        // we're intentionally allowing setting quorum value higher than the number of guardians
        if (quorum != newValue) {
            quorum = newValue;
            emit GuardianQuorumChanged(newValue);
        }
    }

    /**
     * Returns guardian committee member list.
     */
    function getGuardians() external view returns (address[] memory) {
        return guardians;
    }

    /**
     * Checks whether the given address is a guardian.
     */
    function isGuardian(address addr) external view returns (bool) {
        return _isGuardian(addr);
    }

    function _isGuardian(address addr) internal view returns (bool) {
        return guardianIndicesOneBased[addr] > 0;
    }

    /**
     * Returns index of the guardian, or -1 if the address is not a guardian.
     */
    function getGuardianIndex(address addr) external view returns (int256) {
        return _getGuardianIndex(addr);
    }

    function _getGuardianIndex(address addr) internal view returns (int256) {
        return int256(guardianIndicesOneBased[addr]) - 1;
    }

    /**
     * Adds a guardian address and sets a new quorum value.
     * Reverts if the address is already a guardian.
     *
     * Only callable by the owner.
     */
    function addGuardian(address addr, uint256 newQuorum) external onlyDao {
        _addGuardian(addr);
        _setGuardianQuorum(newQuorum);
    }

    /**
     * Adds a set of guardian addresses and sets a new quorum value.
     * Reverts any of them is already a guardian.
     *
     * Only callable by the owner.
     */
    function addGuardians(address[] memory addresses, uint256 newQuorum) external onlyDao {
        for (uint256 i = 0; i < addresses.length; ++i) {
            _addGuardian(addresses[i]);
        }
        _setGuardianQuorum(newQuorum);
    }

    function _addGuardian(address _newGuardian) internal {
        if (_newGuardian == address(0)) revert Errors.InvalidAddr();
        if (_isGuardian(_newGuardian)) revert Errors.DuplicateAddress();
        guardians.push(_newGuardian);
        guardianIndicesOneBased[_newGuardian] = guardians.length;
        emit GuardianAdded(_newGuardian);
    }

    /**
     * Removes a guardian with the given address and sets a new quorum value.
     *
     * Only callable by the owner.
     */
    function removeGuardian(address addr, uint256 newQuorum) external onlyDao {
        uint256 indexOneBased = guardianIndicesOneBased[addr];
        if (indexOneBased == 0) revert Errors.NotAGuardian();

        uint256 totalGuardians = guardians.length;
        assert(indexOneBased <= totalGuardians);

        if (indexOneBased != totalGuardians) {
            address addrToMove = guardians[totalGuardians - 1];
            guardians[indexOneBased - 1] = addrToMove;
            guardianIndicesOneBased[addrToMove] = indexOneBased;
        }

        guardianIndicesOneBased[addr] = 0;
        guardians.pop();

        _setGuardianQuorum(newQuorum);

        emit GuardianRemoved(addr);
    }

    function mint(
        address token,
        bytes32 txHash,
        address destAddr,
        uint256 stakingOutputIdx,
        uint256 inclusionHeight,
        uint256 stakingAmount,
        Signature[] calldata sortedGuardianSignatures
    ) external whenNotPaused {
        if (quorum == 0 || sortedGuardianSignatures.length < quorum) revert Errors.DepositNoQuorum();

        bytes32 msgHash = _verifySignatures(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );
        if (mintMsgHash[msgHash] != address(0)) {
            revert Errors.MsgHashAlreadyMint();
        }
        mintMsgHash[msgHash] = destAddr;

        IObeliskNetwork(obeliskNetwork).mint(token, destAddr, stakingAmount);

        emit TokenMinted(msgHash, txHash, token, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount);
    }

    function _verifySignatures(
        address token,
        bytes32 txHash,
        address destAddr,
        uint256 stakingOutputIdx,
        uint256 inclusionHeight,
        uint256 stakingAmount,
        Signature[] memory sigs
    ) internal view returns (bytes32 msgHash) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        msgHash = keccak256(
            abi.encodePacked(
                MINT_MESSAGE_PREFIX, txHash, token, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount
            )
        );
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));

        address prevSignerAddr = address(0);
        for (uint256 i = 0; i < sigs.length; ++i) {
            address signerAddr = ECDSA.recover(prefixedHash, sigs[i].r, sigs[i].vs);
            if (!_isGuardian(signerAddr)) revert Errors.InvalidSignature();
            if (signerAddr <= prevSignerAddr) revert Errors.SignaturesNotSorted();
            prevSignerAddr = signerAddr;
        }
    }

    /**
     * @notice Contract type id
     */
    function typeId() public pure override returns (bytes32) {
        return keccak256("MintSecurity");
    }

    /**
     * @notice Contract version
     */
    function version() public pure override returns (uint8) {
        return 1;
    }

    /**
     * @notice stop protocol
     */
    function pause() external onlyDao {
        _pause();
    }

    /**
     * @notice start protocol
     */
    function unpause() external onlyDao {
        _unpause();
    }
}
