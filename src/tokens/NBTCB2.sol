// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

contract NBTCB2 is BaseToken {
    constructor(address _tokenAdmin) BaseToken("Obelisk NBTC-B2", "nBTC-B2", _tokenAdmin) {}
}
