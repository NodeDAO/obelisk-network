// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/OBTC.sol";
import {TestToken, TestToken2} from "test/TestToken.sol";
import "src/tokens/OYBTCB2.sol";
import "src/tokens/OYBTCBBL.sol";
import "src/core/ObeliskNetwork.sol";
import "src/strategies/DefiStrategy.sol";
import "src/core/MintSecurity.sol";
import "src/core/MintStrategy.sol";
import "src/core/StrategyManager.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

// forge script script/Deploy-testnet.s.sol:HoleskyDeployObelisk  --rpc-url $HOLESKY_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract HoleskyDeployObelisk is Script {
    address _dao = 0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address _obeliskNetworkImple = address(new ObeliskNetwork());
        ObeliskNetwork _obeliskNetwork = ObeliskNetwork(payable(new ERC1967Proxy(_obeliskNetworkImple, "")));

        console.log("=====obeliskNetwork=====", address(_obeliskNetwork));

        OBTC _oBTC = new OBTC(address(_obeliskNetwork));
        console.log("=====oBTC=====", address(_oBTC));

        address _mintSecurityImple = address(new MintSecurity());
        MintSecurity _mintSecurity = MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));

        console.log("=====mintSecurity=====", address(_mintSecurity));

        address _strategyManagerImple = address(new StrategyManager());
        StrategyManager _strategyManager = StrategyManager(payable(new ERC1967Proxy(_strategyManagerImple, "")));

        console.log("=====strategyManager=====", address(_strategyManager));

        address[] memory _mintStrategies = deployMintStrategys(address(_obeliskNetwork), address(_oBTC));
        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_oBTC);
        _obeliskNetwork.initialize(_dao, _dao, _dao, address(_mintSecurity), _tokenAddrs, _mintStrategies);

        // _mintSecurity.initialize(_dao, _dao, address(_obeliskNetwork));

        address b2 = deployStrategysB2(address(_oBTC), address(_strategyManager));
        address bbl = deployStrategysBBL(address(_oBTC), address(_strategyManager));
        address[] memory _strategies = new address[](2);
        _strategies[0] = address(b2);
        _strategies[1] = address(bbl);

        _strategyManager.initialize(_dao, _dao, _strategies);

        vm.stopBroadcast();
    }

    function deployMintStrategys(address _obeliskNetwork, address _oBTC) internal returns (address[] memory) {
        address _mintStrategyImple = address(new MintStrategy());
        MintStrategy _mintStrategy = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));
        MintStrategy _mintStrategy2 = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));

        console.log("=====mintStrategy=====", address(_mintStrategy));
        console.log("=====mintStrategy2=====", address(_mintStrategy2));

        address _testBTC = address(new TestToken("test BTC", "tBTC", _dao));
        _mintStrategy.initialize(_dao, _dao, address(_obeliskNetwork), _dao, address(_testBTC), address(_oBTC), 10);
        address _testBTC2 = address(new TestToken2("test BTC18", "tBTC18", _dao));
        _mintStrategy2.initialize(_dao, _dao, address(_obeliskNetwork), _dao, address(_testBTC2), address(_oBTC), 10);

        console.log("=====testBTC=====", address(_testBTC));
        console.log("=====testBTC2=====", address(_testBTC2));

        address[] memory _mintStrategies = new address[](2);
        _mintStrategies[0] = address(_mintStrategy);
        _mintStrategies[1] = address(_mintStrategy2);
        return _mintStrategies;
    }

    function deployStrategysB2(address _obBTC, address _strategyManager) internal returns (address) {
        address _defiStrategyImple = address(new DefiStrategy());
        DefiStrategy _defiStrategyB2 = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        console.log("=====defiStrategyB2=====", address(_defiStrategyB2));
        OYBTCB2 nBTCb2 = new OYBTCB2(address(_defiStrategyB2));
        console.log("=====nBTCb2=====", address(nBTCb2));

        _defiStrategyB2.initialize(
            _dao, _dao, _strategyManager, _dao, _dao, 10000, 10000000000000, address(_obBTC), address(nBTCb2)
        );

        return address(_defiStrategyB2);
    }

    function deployStrategysBBL(address _obBTC, address _strategyManager) internal returns (address) {
        address _defiStrategyImple = address(new DefiStrategy());
        DefiStrategy _defiStrategyBBL = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        console.log("=====defiStrategyBBL=====", address(_defiStrategyBBL));
        OYBTCBBL nBTCbbl = new OYBTCBBL(address(_defiStrategyBBL));
        console.log("=====nBTCbbl=====", address(nBTCbbl));

        _defiStrategyBBL.initialize(
            _dao, _dao, _strategyManager, _dao, _dao, 10000, 10000000000000, address(_obBTC), address(nBTCbbl)
        );

        return address(_defiStrategyBBL);
    }
}
