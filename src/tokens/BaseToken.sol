// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "src/interfaces/IBaseToken.sol";
import {Errors} from "src/libraries/Errors.sol";
import "src/modules/BlackList.sol";

abstract contract BaseToken is ERC20, Ownable, BlackList, IBaseToken {
    address public tokenAdmin;

    modifier onlyTokenAdmin() {
        if (msg.sender != tokenAdmin) revert Errors.PermissionDenied();
        _;
    }

    constructor(string memory _name, string memory _symbol, address _tokenAdmin) ERC20(_name, _symbol) {
        tokenAdmin = _tokenAdmin;
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        if (msg.sender == tokenAdmin) {
            return;
        }

        if (isBlackListed[from] || isBlackListed[to]) {
            revert Errors.BlackListed();
        }
    }

    /**
     * @notice mint
     * @param _amount mint amount
     * @param _account mint account
     */
    function whiteListMint(uint256 _amount, address _account) external onlyTokenAdmin {
        _mint(_account, _amount);
    }

    /**
     * @notice burn
     * @param _amount burn amount
     * @param _account burn account
     */
    function whiteListBurn(uint256 _amount, address _account) external onlyTokenAdmin {
        _burn(_account, _amount);
    }

    function changeTokenAdmin(address _tokenAdmin) public onlyOwner {
        emit TokenAdminChanged(tokenAdmin, _tokenAdmin);
        tokenAdmin = payable(_tokenAdmin);
    }

    function setBlackListAdmin(address _blackListAdmin) public onlyOwner {
        _setBlackListAdmin(_blackListAdmin);
    }
}
