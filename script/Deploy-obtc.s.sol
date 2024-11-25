// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/OBTC.sol";

// forge script script/Deploy-obtc.s.sol:DeploySepoliaOBTC  --rpc-url $SEPOLIA_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract DeploySepoliaOBTC is Script {
    address _dao = 0xdCAF3Ed6E28047f4480900A39a318D8377AD36e3;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        OBTC _oBTC = new OBTC(address(0), _dao);
        console.log("=====_oBTC=====", address(_oBTC));

        vm.stopBroadcast();
    }
}

// forge script script/Deploy-obtc.s.sol:DeployOPSepoliaOBTC  --rpc-url $OP_SEPOLIA_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract DeployOPSepoliaOBTC is Script {
    address _dao = 0xdCAF3Ed6E28047f4480900A39a318D8377AD36e3;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        OBTC _oBTC = new OBTC(address(0), _dao);
        console.log("=====op_oBTC=====", address(_oBTC));

        vm.stopBroadcast();
    }
}

// forge script script/Deploy-obtc.s.sol:DeployOPModeOBTC  --rpc-url $MODE_RPC_URL --broadcast --verify --verifier blockscout --verifier-url https://explorer.mode.network/api\?  --retries 10 --delay 30
contract DeployOPModeOBTC is Script {
    address _dao = 0x8dE9098d54695e9E238384Cfb80E2894FdFD2766;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        OBTC _oBTC = new OBTC(address(0), _dao);
        // _oBTC.transferOwnership(_dao);
        console.log("=====mode_oBTC=====", address(_oBTC));

        vm.stopBroadcast();
    }
}

// forge script script/Deploy-obtc.s.sol:DeployTaikoOBTC  --rpc-url $TAIKO_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract DeployTaikoOBTC is Script {
    address _dao = 0xa2d065f7c5230673A16894FBAc3CC964aB85EFb8;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        OBTC _oBTC = new OBTC(address(0), _dao);
        // _oBTC.transferOwnership(_dao);
        console.log("=====taiko_oBTC=====", address(_oBTC));

        vm.stopBroadcast();
    }
}
