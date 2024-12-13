// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/ObeliskBTC.sol";
import {TestToken, TestToken2} from "test/TestContract.sol";
import "src/core/ObeliskNetwork.sol";
import "src/core/ObeliskCustody.sol";
import "src/strategies/DefiStrategy.sol";
import "src/core/MintSecurity.sol";
import "src/core/MintStrategy.sol";
import "src/core/StrategyManager.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

// forge script script/Deposit-testnet.sol:DepositTest  --rpc-url $HOLESKY_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract DepositTest is Script {
    address _dao = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;

    // modify obtc address for first deploy ObeliskBTC
    ObeliskBTC public _obeliskBTC = ObeliskBTC(0x787652637307A049f4454f6F8F9D5Ba219200fd9);
    ObeliskNetwork _obeliskNetwork = ObeliskNetwork(0xd9751873f661fbca1E66943B5Da39171e7B10a9B);
    TestToken _testBTC = TestToken(0x227E33c50feb58e0e78fD17be23DdbB696a45Fc0);
    address _mintStrategy = 0x07D0a593bD9254b131e48883a10449df82fa925E;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY2");
        vm.startBroadcast(deployerPrivateKey);

        _testBTC.mint(_dao, 1e10);
        _testBTC.approve(_mintStrategy, 1e10);
        _obeliskNetwork.deposit(_mintStrategy, address(_obeliskBTC), 1e8);

        vm.stopBroadcast();
    }
}

// forge script script/Deposit-testnet.sol:WithdrawTest  --rpc-url $HOLESKY_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract WithdrawTest is Script {
    address _dao = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;

    // modify obtc address for first deploy ObeliskBTC
    ObeliskBTC public _obeliskBTC = ObeliskBTC(0x787652637307A049f4454f6F8F9D5Ba219200fd9);
    ObeliskNetwork _obeliskNetwork = ObeliskNetwork(0xd9751873f661fbca1E66943B5Da39171e7B10a9B);
    TestToken _testBTC = TestToken(0x227E33c50feb58e0e78fD17be23DdbB696a45Fc0);
    address _mintStrategy = 0x07D0a593bD9254b131e48883a10449df82fa925E;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY2");
        vm.startBroadcast(deployerPrivateKey);

        _obeliskBTC.approve(address(_obeliskNetwork), 1e7);
        _obeliskNetwork.requestWithdrawals(_mintStrategy, address(_obeliskBTC), 1e7, "0x");

        vm.stopBroadcast();
    }
}
