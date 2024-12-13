// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "openzeppelin-contracts/access/AccessControl.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {IMintableERC20} from "src/interfaces/IMintableERC20.sol";

contract ObeliskBTC is IMintableERC20, ERC20, AccessControl, Pausable {
    error AccountIsBlacklisted(address account);

    // 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // 0x3c11d16cbaffd01df69ce1c404f6340ee057498f5f00246190ea54220576a848
    bytes32 internal constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Blacklist mapping
    mapping(address => bool) private _blacklist;

    // Initialize the contract
    constructor(string memory name, string memory symbol, address admin) ERC20(name, symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // decimals 8, The native precision of BTC is 8
    function decimals() public pure virtual override returns (uint8) {
        return 8;
    }

    // Add address to blacklist
    function addBlackList(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _blacklist[account] = true;
    }

    // Remove address from blacklist
    function removeFromBlacklist(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _blacklist[account] = false;
    }

    // Check if an address is blacklisted
    function isBlackListed(address account) public view returns (bool) {
        return _blacklist[account];
    }

    // Pause the contract (can be done by PAUSER_ROLE)
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    // Unpause the contract (can only be done by the admin role)
    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Internal function to check paused and blacklist status
    function _checkPausedAndBlacklist(address account) internal view whenNotPaused {
        if (_blacklist[account]) {
            revert AccountIsBlacklisted(account);
        }
    }

    function burnerRole() external pure returns (bytes32) {
        return BURNER_ROLE;
    }

    function minterRole() external pure returns (bytes32) {
        return MINTER_ROLE;
    }

    function pauserRole() external pure returns (bytes32) {
        return PAUSER_ROLE;
    }

    // Override ERC20's `_transfer` function to include blacklist check and paused status
    function _transfer(address from, address to, uint256 amount) internal override {
        _checkPausedAndBlacklist(from);
        _checkPausedAndBlacklist(to);
        super._transfer(from, to, amount);
    }

    // Public burn function to include blacklist check and paused status
    function burn(address account, uint256 amount) external onlyRole(BURNER_ROLE) {
        _checkPausedAndBlacklist(account); // Check blacklist and paused status
        _burn(account, amount); // Actual burn logic
    }

    // Public mint function to include blacklist check and paused status
    function mint(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        _checkPausedAndBlacklist(account); // Check blacklist and paused status
        _mint(account, amount); // Actual mint logic
    }
}
