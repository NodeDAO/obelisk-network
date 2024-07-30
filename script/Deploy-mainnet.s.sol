// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/OBTC.sol";
import {TestToken, TestToken2} from "test/TestContract.sol";
import "src/tokens/OYBTCB2.sol";
import "src/tokens/OYBTCBBN.sol";
import "src/tokens/OYBTCFBTC.sol";
import "src/core/ObeliskNetwork.sol";
import "src/strategies/DefiStrategy.sol";
import "src/core/MintSecurity.sol";
import "src/core/MintStrategy.sol";
import "src/core/StrategyManager.sol";
import "src/TimelockController.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

// forge script script/Deploy-mainnet.s.sol:MainnetDeployObelisk  --rpc-url $MAINNET_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract MainnetDeployObelisk is Script {
    address _dao = 0x8cC49b20c1d8B7129D76ca3E9EFacD968728ca95;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address[] memory proposers = new address[](2);
        address[] memory executors = new address[](1);
        proposers[0] = 0x3E29BF7B650b8910F3B4DDda5b146e8716c683a6; // nodedao.eth
        proposers[1] = _dao;
        executors[0] = _dao;

        address _owner = address(new TimelockController(3600, proposers, executors, address(0)));
        console.log("=====timelock=====", address(_owner));

        address _obeliskNetworkImple = address(new ObeliskNetwork());
        ObeliskNetwork _obeliskNetwork = ObeliskNetwork(payable(new ERC1967Proxy(_obeliskNetworkImple, "")));

        console.log("=====obeliskNetwork=====", address(_obeliskNetwork));

        OBTC _oBTC = new OBTC(address(_obeliskNetwork), _dao);
        // transfer owner
        _oBTC.transferOwnership(_owner);
        console.log("=====oBTC=====", address(_oBTC));

        address _mintSecurityImple = address(new MintSecurity());
        MintSecurity _mintSecurity = MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));

        console.log("=====mintSecurity=====", address(_mintSecurity));

        address _strategyManagerImple = address(new StrategyManager());
        StrategyManager _strategyManager = StrategyManager(payable(new ERC1967Proxy(_strategyManagerImple, "")));

        console.log("=====strategyManager=====", address(_strategyManager));

        address[] memory _mintStrategies = deployMintStrategys(_owner, address(_obeliskNetwork), address(_oBTC));
        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_oBTC);
        _obeliskNetwork.initialize(_owner, _dao, _dao, address(_mintSecurity), _tokenAddrs, _mintStrategies);

        _mintSecurity.initialize(_owner, _dao, address(_obeliskNetwork));

        address fbtc = deployStrategysFBTC(_owner, address(_oBTC), address(_strategyManager));
        address b2 = deployStrategysB2(_owner, address(_oBTC), address(_strategyManager));
        address bbl = deployStrategysBBL(_owner, address(_oBTC), address(_strategyManager));
        address[] memory _strategies = new address[](3);
        _strategies[0] = address(b2);
        _strategies[1] = address(bbl);
        _strategies[2] = address(fbtc);

        _strategyManager.initialize(_owner, _dao, _strategies);

        vm.stopBroadcast();
    }

    function deployMintStrategys(address _ownerAddr, address _obeliskNetwork, address _oBTC)
        internal
        returns (address[] memory)
    {
        address _mintStrategyImple = address(new MintStrategy());
        MintStrategy _mintStrategy = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));
        address fbtc = 0xC96dE26018A54D51c097160568752c4E3BD6C364;

        console.log("=====mintStrategy-fbtc=====", address(_mintStrategy));
        console.log("=====fbtc=====", address(fbtc));

        _mintStrategy.initialize(_ownerAddr, _dao, address(_obeliskNetwork), address(fbtc), address(_oBTC), 21600); // delay 3 day

        address[] memory _mintStrategies = new address[](1);
        _mintStrategies[0] = address(_mintStrategy);
        return _mintStrategies;
    }

    function deployStrategysB2(address _ownerAddr, address _oBTC, address _strategyManager)
        internal
        returns (address)
    {
        address _defiStrategyImple = address(new DefiStrategy());
        DefiStrategy _defiStrategyB2 = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        console.log("=====defiStrategyB2=====", address(_defiStrategyB2));
        OYBTCB2 oyBTCb2 = new OYBTCB2(address(_defiStrategyB2), _dao);
        // transfer owner
        oyBTCb2.transferOwnership(_ownerAddr);
        console.log("=====nBTCb2=====", address(oyBTCb2));

        _defiStrategyB2.initialize(
            _ownerAddr, _dao, _strategyManager, _dao, 10000, 10000000000000, address(_oBTC), address(oyBTCb2)
        );

        return address(_defiStrategyB2);
    }

    function deployStrategysBBL(address _ownerAddr, address _oBTC, address _strategyManager)
        internal
        returns (address)
    {
        address _defiStrategyImple = address(new DefiStrategy());
        DefiStrategy _defiStrategyBBL = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        console.log("=====defiStrategyBBL=====", address(_defiStrategyBBL));
        OYBTCBBN oyBTCbbl = new OYBTCBBN(address(_defiStrategyBBL), _dao);
        // transfer owner
        oyBTCbbl.transferOwnership(_ownerAddr);
        console.log("=====nBTCbbl=====", address(oyBTCbbl));

        _defiStrategyBBL.initialize(
            _ownerAddr, _dao, _strategyManager, _dao, 10000, 10000000000000, address(_oBTC), address(oyBTCbbl)
        );

        return address(_defiStrategyBBL);
    }

    function deployStrategysFBTC(address _ownerAddr, address _oBTC, address _strategyManager)
        internal
        returns (address)
    {
        address _defiStrategyImple = address(new DefiStrategy());
        DefiStrategy _defiStrategyFBTC = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        console.log("=====defiStrategyFBTC=====", address(_defiStrategyFBTC));
        OYBTCFBTC oyBTCfbtc = new OYBTCFBTC(address(_defiStrategyFBTC), _dao);
        // transfer owner
        oyBTCfbtc.transferOwnership(_ownerAddr);
        console.log("=====oyBTCfbtc=====", address(oyBTCfbtc));

        _defiStrategyFBTC.initialize(
            _ownerAddr, _dao, _strategyManager, _dao, 10000, 10000000000000, address(_oBTC), address(oyBTCfbtc)
        );

        return address(_defiStrategyFBTC);
    }
}