// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

contract NBTCBBL is BaseToken {
    constructor(address _tokenAdmin) BaseToken("Obelisk NBTC-BBL", "nBTC-BBL", _tokenAdmin) {}
}
