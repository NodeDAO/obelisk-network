// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

/**
 * @title Obelisk BTC
 * @author Obelisk
 * @notice oBTC is an equivalent asset mapping of BTC
 */
contract OBTC is BaseToken {
    constructor(address _tokenAdmin, address _blackListAdmin)
        BaseToken("Obelisk BTC", "oBTC", _tokenAdmin, _blackListAdmin)
    {}
}
