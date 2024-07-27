// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title Obelisk Yield
 * @author Obelisk
 * @notice Babylon Yield
 */
contract OYBTCBBN is BaseToken {
    constructor(address _tokenAdmin, address _blackListAdmin)
        BaseToken("Obelisk Yield BTC-BBN", "oyBTC-BBN", _tokenAdmin, _blackListAdmin)
    {}
}
