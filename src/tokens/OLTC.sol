// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title Obelisk LTC
 * @author Obelisk
 * @notice oLTC is an equivalent asset mapping of LTC
 */
contract OLTC is BaseToken {
    constructor(address _tokenAdmin) BaseToken("Obelisk LTC", "oLTC", _tokenAdmin) {}
}
