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

// forge script script/Deploy-testnet.s.sol:HoleskyDeployObelisk  --rpc-url $HOLESKY_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract HoleskyDeployObelisk is Script {
    address _dao = 0x892e7c8C5E716e17891ABf9395a0de1f2fc84786;

    // modify obtc address for first deploy ObeliskBTC
    ObeliskBTC public _obeliskBTC = ObeliskBTC(0x787652637307A049f4454f6F8F9D5Ba219200fd9);

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY2");
        vm.startBroadcast(deployerPrivateKey);

        console.log("=====oBTC=====", address(_obeliskBTC));

        address _obeliskNetworkImple = address(new ObeliskNetwork());
        ObeliskNetwork _obeliskNetwork = ObeliskNetwork(payable(new ERC1967Proxy(_obeliskNetworkImple, "")));

        console.log("=====obeliskNetwork=====", address(_obeliskNetwork));

        _obeliskBTC.grantRole(_obeliskBTC.minterRole(), address(_obeliskNetwork));
        _obeliskBTC.grantRole(_obeliskBTC.burnerRole(), address(_obeliskNetwork));

        address _mintSecurityImple = address(new MintSecurity());
        MintSecurity _mintSecurity = MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));

        console.log("=====mintSecurity=====", address(_mintSecurity));

        address[] memory _mintStrategies = deployMintStrategys(address(_obeliskNetwork), address(_obeliskBTC));
        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_obeliskBTC);
        _obeliskNetwork.initialize(_dao, _dao, _dao, address(_mintSecurity), _tokenAddrs, _mintStrategies);

        _mintSecurity.initialize(_dao, _dao, address(_obeliskNetwork));

        vm.stopBroadcast();
    }

    function deployMintStrategys(address _obeliskNetwork, address _oBTC) internal returns (address[] memory) {
        address _mintStrategyImple = address(new MintStrategy());
        MintStrategy _mintStrategy = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));
        MintStrategy _mintStrategy2 = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));

        console.log("=====mintStrategy=====", address(_mintStrategy));
        console.log("=====mintStrategy2=====", address(_mintStrategy2));

        TestToken _testBTC = new TestToken("test BTC", "tBTC", _dao);
        _testBTC.grantRole(_testBTC.minterRole(), _dao);
        _testBTC.grantRole(_testBTC.burnerRole(), _dao);

        _mintStrategy.initialize(_dao, _dao, address(_obeliskNetwork), address(_testBTC), address(_oBTC), 10);
        TestToken2 _testBTC2 = new TestToken2("test BTC18", "tBTC18", _dao);
        _testBTC2.grantRole(_testBTC2.minterRole(), _dao);
        _testBTC2.grantRole(_testBTC2.burnerRole(), _dao);

        _mintStrategy2.initialize(_dao, _dao, address(_obeliskNetwork), address(_testBTC2), address(_oBTC), 10);

        console.log("=====testBTC=====", address(_testBTC));
        console.log("=====testBTC2=====", address(_testBTC2));

        address[] memory _mintStrategies = new address[](2);
        _mintStrategies[0] = address(_mintStrategy);
        _mintStrategies[1] = address(_mintStrategy2);
        return _mintStrategies;
    }
}

// forge script script/Deploy-testnet.s.sol:HoleskyDeployObeliskCustody  --rpc-url $HOLESKY_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract HoleskyDeployObeliskCustody is Script {
    address _dao = 0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address _obeliskCustodyImple = address(new ObeliskCustody());
        ObeliskCustody _obeliskCustody = ObeliskCustody(payable(new ERC1967Proxy(_obeliskCustodyImple, "")));

        console.log("=====obeliskCustodyImple=====", address(_obeliskCustody));

        string[] memory marks = new string[](1);
        marks[0] = "custody";
        string[] memory btcAddrs = new string[](1);
        btcAddrs[0] = "tb1qdlexklc4kq8nzntqkkay06zyjfu790jsuj3wxr";
        _obeliskCustody.initialize(_dao, _dao, marks, btcAddrs);

        vm.stopBroadcast();
    }
}
