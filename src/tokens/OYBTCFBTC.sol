// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title Obelisk Yield
 * @author Obelisk
 * @notice FBTC Yield
 */
contract OYBTCFBTC is BaseToken {
    constructor(address _tokenAdmin, address _blackListAdmin)
        BaseToken("Obelisk Yield BTC-FBTC", "oyBTC-fbtc", _tokenAdmin, _blackListAdmin)
    {}
}
