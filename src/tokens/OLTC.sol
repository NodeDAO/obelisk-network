// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title
 * @author Obelisk
 * @notice
 */
contract OLTC is BaseToken {
    constructor(address _tokenAdmin) BaseToken("Obelisk LTC", "oLTC", _tokenAdmin) {}
}
