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

        address _mintStrategyImple = address(new MintStrategy());
        MintStrategy _mintStrategy = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));

        console.log("=====mintStrategy=====", address(_mintStrategy));

        address _testBTC = address(new TestToken("test BTC", "tBTC", _dao));
        _mintStrategy.initialize(_dao, _dao, address(_obeliskNetwork), _dao, address(_testBTC), address(_oBTC), 10);

        address[] memory _mintStrategies = new address[](1);
        _mintStrategies[0] = address(_mintStrategy);

        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_oBTC);
        _obeliskNetwork.initialize(_dao, _dao, _dao, address(_mintSecurity), _tokenAddrs, _mintStrategies);

        _mintSecurity.initialize(_dao, _dao, address(_obeliskNetwork));

        address[] memory _strategies = deployStrategys(address(_oBTC), address(_strategyManager));
        _strategyManager.initialize(_dao, _dao, _strategies);

        vm.stopBroadcast();
    }

    function deployStrategys(address _obBTC, address _strategyManager) internal returns (address[] memory) {
        address _defiStrategyImple = address(new DefiStrategy());
        DefiStrategy _defiStrategyB2 = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        DefiStrategy _defiStrategyBBL = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        console.log("=====defiStrategyB2=====", address(_defiStrategyB2));
        console.log("=====defiStrategyBBL=====", address(_defiStrategyBBL));
        OYBTCB2 nBTCb2 = new OYBTCB2(address(_defiStrategyB2));
        OYBTCBBL nBTCbbl = new OYBTCBBL(address(_defiStrategyBBL));
        console.log("=====nBTCb2=====", address(nBTCb2));
        console.log("=====nBTCbbl=====", address(nBTCbbl));

        _defiStrategyB2.initialize(_dao, _dao, _strategyManager, _dao, _dao, 10000, address(_obBTC), address(nBTCb2));
        _defiStrategyBBL.initialize(_dao, _dao, _strategyManager, _dao, _dao, 10000, address(_obBTC), address(nBTCbbl));

        address[] memory _strategies = new address[](2);
        _strategies[0] = address(_defiStrategyB2);
        _strategies[1] = address(_defiStrategyBBL);
        return _strategies;
    }
}
