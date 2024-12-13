// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/ObeliskBTC.sol";
import "src/core/ObeliskNetwork.sol";
import "src/core/ObeliskCustody.sol";
import "src/strategies/DefiStrategy.sol";
import "src/core/MintSecurity.sol";
import "src/core/MintStrategy.sol";
import "src/core/StrategyManager.sol";
import "src/TimelockController.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

// forge script script/Deploy-mainnet.s.sol:MainnetDeployObelisk  --rpc-url $EXSAT_RPC_URL --broadcast --legacy --gas-price 50000000 --verify --verifier=blockscout --verifier-url=https://scan.exsat.network/api/ --retries 10 --delay 30
contract MainnetDeployObelisk is Script {
    address _dao = 0xc1c6c9D10a6Fe5FBCA2E67EBC72229d9855a7ADb;
    address _owner = 0xc1c6c9D10a6Fe5FBCA2E67EBC72229d9855a7ADb;

    // modify obtc address for first deploy ObeliskBTC
    ObeliskBTC _obeliskBTC = ObeliskBTC(0x787652637307A049f4454f6F8F9D5Ba219200fd9);

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
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

        // address _strategyManagerImple = address(new StrategyManager());
        // StrategyManager _strategyManager = StrategyManager(payable(new ERC1967Proxy(_strategyManagerImple, "")));

        // console.log("=====strategyManager=====", address(_strategyManager));

        // todo modify Mint token
        address[] memory _mintStrategies = deployMintStrategys(_owner, address(_obeliskNetwork), address(_obeliskBTC));
        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_obeliskBTC);
        _obeliskNetwork.initialize(_owner, _dao, _dao, address(_mintSecurity), _tokenAddrs, _mintStrategies);

        _mintSecurity.initialize(_owner, _dao, address(_obeliskNetwork));

        // address fbtc = deployStrategysFBTC(_owner, address(_oBTC), address(_strategyManager));
        // address b2 = deployStrategysB2(_owner, address(_oBTC), address(_strategyManager));
        // address bbl = deployStrategysBBL(_owner, address(_oBTC), address(_strategyManager));
        // address[] memory _strategies = new address[](3);
        // _strategies[0] = address(b2);
        // _strategies[1] = address(bbl);
        // _strategies[2] = address(fbtc);

        // _strategyManager.initialize(_owner, _dao, _strategies);

        vm.stopBroadcast();
    }

    function deployMintStrategys(address _ownerAddr, address _obeliskNetwork, address _oBTC)
        internal
        returns (address[] memory)
    {
        address _mintStrategyImple = address(new MintStrategy());
        MintStrategy _mintStrategy = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));
        address ibtc = 0x8154Aaf094c2f03Ad550B6890E1d4264B5DdaD9A;

        console.log("=====mintStrategy-ibtc=====", address(_mintStrategy));
        console.log("=====ibtc=====", address(ibtc));

        _mintStrategy.initialize(_ownerAddr, _dao, address(_obeliskNetwork), address(ibtc), address(_oBTC), 21600); // delay 3 day

        address[] memory _mintStrategies = new address[](1);
        _mintStrategies[0] = address(_mintStrategy);
        return _mintStrategies;
    }
}

// forge script script/Deploy-mainnet.s.sol:MainnetDeployObeliskCustody  --rpc-url $MAINNET_RPC_URL --broadcast --verify  --retries 10 --delay 30
contract MainnetDeployObeliskCustody is Script {
    address _dao = 0x8cC49b20c1d8B7129D76ca3E9EFacD968728ca95;
    address _owner = 0xe4c555c2aa8F7FDB7Baf90039b3A583c8E312f20;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address _obeliskCustodyImple = address(new ObeliskCustody());
        ObeliskCustody _obeliskCustody = ObeliskCustody(payable(new ERC1967Proxy(_obeliskCustodyImple, "")));

        console.log("=====obeliskCustodyImple=====", address(_obeliskCustody));

        string[] memory marks = new string[](0);
        string[] memory btcAddrs = new string[](0);
        _obeliskCustody.initialize(_owner, _dao, marks, btcAddrs);

        vm.stopBroadcast();
    }
}
