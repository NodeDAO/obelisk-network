// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/ObeliskBTC.sol";

// forge script script/ForgeCreate2DeployTest.s.sol:DeployTestnetOBTC  --rpc-url $SEPOLIA_RPC_URL --broadcast --verify  --retries 10 --delay 30
// forge script script/ForgeCreate2DeployTest.s.sol:DeployTestnetOBTC  --rpc-url $HOLESKY_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract DeployTestnetOBTC is Script {
    address _admin = 0xc1c6c9D10a6Fe5FBCA2E67EBC72229d9855a7ADb;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY3");
        vm.startBroadcast(deployerPrivateKey);

        // 0x258ece49f7e2206de694ec41  (Obelisk Create2)
        //        bytes32 salt = 0x0000000000000000000000000000000000000000258ece49f7e2206de694ec41;
        bytes32 salt = 0x00000000000000000000000000000000000000000182adf77a354ea6c09821c1;

        ObeliskBTC obtc = new ObeliskBTC{salt: salt}("Obelisk BTC", "oBTC.x", _admin);
        console.log("===obtc create2 address:", address(obtc));

        vm.stopBroadcast();
    }
}
