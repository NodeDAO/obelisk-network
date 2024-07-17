// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "src/tokens/BaseToken.sol";

contract TestToken is BaseToken {
    constructor(string memory _name, string memory _symbol, address _tokenAdmin)
        BaseToken(_name, _symbol, _tokenAdmin)
    {}
}

contract TestToken2 is BaseToken {
    constructor(string memory _name, string memory _symbol, address _tokenAdmin)
        BaseToken(_name, _symbol, _tokenAdmin)
    {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
