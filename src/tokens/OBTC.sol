// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title
 * @author Obelisk
 * @notice
 */
contract OBTC is BaseToken {
    constructor(address _tokenAdmin) BaseToken("Obelisk BTC", "oBTC", _tokenAdmin) {}
}
