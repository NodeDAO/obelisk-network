// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/ObeliskBTC.sol";
import "script/interfaces/ImmutableCreate2Factory.sol";

// forge script script/Deploy-obtc-testnet.s.sol:DeployTestnetOBTC  --rpc-url $HOLESKY_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract DeployTestnetOBTC is Script {
    ImmutableCreate2Factory private constant IMMUTABLE_CREATE2_FACTORY =
        ImmutableCreate2Factory(0x0000000000FFe8B47B3e2130213B802212439497);

    address _admin = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;

    address public expectOBTCAddress = 0x787652637307A049f4454f6F8F9D5Ba219200fd9;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY2");
        vm.startBroadcast(deployerPrivateKey);

        // CREATE2 salt (20-byte caller or zero address + 12-byte salt).
        bytes32 salt = 0x0000000000000000000000000000000000000000155c2a3590621fc9be4bc871;

        bytes memory initCode =
            abi.encodePacked(type(ObeliskBTC).creationCode, abi.encode("Obelisk BTC", "oBTC.x", _admin));

        // Deploy the contract via ImmutableCreate2Factory.
        // Packed and ABI-encoded contract bytecode and constructor arguments.
        address contractAddress = IMMUTABLE_CREATE2_FACTORY.safeCreate2(salt, initCode);
        console.log("===create2 contractAddress:", contractAddress);

        assert(contractAddress == expectOBTCAddress);

        vm.stopBroadcast();
    }
}
