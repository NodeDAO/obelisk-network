// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

contract OYBTCB2 is BaseToken {
    constructor(address _tokenAdmin) BaseToken("Obelisk Yield BTC-B2", "oyBTC-B2", _tokenAdmin) {}
}
