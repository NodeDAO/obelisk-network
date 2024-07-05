// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/OBBTC.sol";
import "src/tokens/NBTCB2.sol";
import "src/tokens/NBTCBBL.sol";
import "src/core/ObeliskNetwork.sol";
import "src/strategies/DefiStrategy.sol";
import "src/core/MintSecurity.sol";
import "src/core/StrategyManager.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ObeliskNetworkTest is Test {
    address _dao = address(1000);

    OBBTC public _obBTC;
    ObeliskNetwork public _obeliskNetwork;
    StrategyManager public _strategyManager;
    MintSecurity public _mintSecurity;
    DefiStrategy public _defiStrategyB2;
    DefiStrategy public _defiStrategyBBL;

    function setUp() public {
        address _obeliskNetworkImple = address(new ObeliskNetwork());
        _obeliskNetwork = ObeliskNetwork(payable(new ERC1967Proxy(_obeliskNetworkImple, "")));

        console.log("=====obeliskNetwork=====", address(_obeliskNetwork));

        _obBTC = new OBBTC(address(_obeliskNetwork));

        console.log("=====obBTC=====", address(_obBTC));

        address _mintSecurityImple = address(new MintSecurity());
        // MINT_MESSAGE_PREFIX 0x5706b75259dd61ada5d917cc9b0e797d76b00ca645bc55beb09d4c8ff153ec16
        _mintSecurity = MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));

        console.log("=====mintSecurity=====", address(_mintSecurity));

        address _strategyManagerImple = address(new StrategyManager());
        _strategyManager = StrategyManager(payable(new ERC1967Proxy(_strategyManagerImple, "")));

        console.log("=====strategyManager=====", address(_strategyManager));

        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_obBTC);
        _obeliskNetwork.initialize(_dao, _dao, _dao, address(_mintSecurity), _tokenAddrs);

        _mintSecurity.initialize(_dao, _dao, address(_obeliskNetwork));

        address[] memory _guardians = new address[](3);
        _guardians[0] = 0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc;
        _guardians[1] = 0xc214f4fBb7C9348eF98CC09c83d528E3be2b63A5;
        _guardians[2] = 0xd7189759502ec8bb475e707aCB1C6A4D210e0214;
        vm.prank(address(_dao));
        _mintSecurity.addGuardians(_guardians, 3);

        vm.prank(address(_dao));
        _obeliskNetwork.addAsset(address(_obBTC));

        address[] memory _strategies = deployStrategys();
        _strategyManager.initialize(_dao, _dao, _strategies);
    }

    function deployStrategys() internal returns (address[] memory) {
        address _defiStrategyImple = address(new DefiStrategy());
        _defiStrategyB2 = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        _defiStrategyBBL = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        console.log("=====defiStrategyB2=====", address(_defiStrategyB2));
        console.log("=====defiStrategyBBL=====", address(_defiStrategyBBL));
        NBTCB2 nBTCb2 = new NBTCB2(address(_defiStrategyB2));
        NBTCBBL nBTCbbl = new NBTCBBL(address(_defiStrategyBBL));
        console.log("=====nBTCb2=====", address(nBTCb2));
        console.log("=====nBTCbbl=====", address(nBTCbbl));

        _defiStrategyB2.initialize(
            _dao, _dao, address(_strategyManager), _dao, _dao, 10000, address(_obBTC), address(nBTCb2)
        );
        _defiStrategyBBL.initialize(
            _dao, _dao, address(_strategyManager), _dao, _dao, 10000, address(_obBTC), address(nBTCbbl)
        );

        address[] memory _strategies = new address[](2);
        _strategies[0] = address(_defiStrategyB2);
        _strategies[1] = address(_defiStrategyBBL);
        return _strategies;
    }

    function testMint() public {
        address token = address(_obBTC);
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        uint256 stakingOutputIdx = 0;
        uint256 inclusionHeight = 2865235;
        uint256 stakingAmount = 120000000;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](3);

        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0x2baf05520e83bc494187cf71f9c343f82002e2346a0541b4ac110e8032dca126,
            vs: 0x37459dc63db143cbef86ae9b0393cd16b181b1d9ac561fced18c23035f290da2
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x56657f42c6e54e0e03b0a2f0553ac5035971346b82029b0138e256e0255f4cfe,
            vs: 0xf0f59e5b4b8fb5b3accac5b786403380c79208337d0543dccceca5885963fdc8
        });

        sortedGuardianSignatures[2] = MintSecurity.Signature({
            r: 0x0a323c499c5f3ba1508119b3d29ee063c26a3312dad38dda7912f4a34a10aab7,
            vs: 0x7620506989779ce6e5ea47624de9d3dfd9d83411174178e8d7aab83793fe75f8
        });

        _mintSecurity.mint(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );

        assertEq(_obBTC.balanceOf(destAddr), stakingAmount);
    }

    function testFailMint2() public {
        address token = address(_obBTC);
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        uint256 stakingOutputIdx = 0;
        uint256 inclusionHeight = 2865235;
        uint256 stakingAmount = 120000000;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](3);

        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0x2baf05520e83bc494187cf71f9c343f82002e2346a0541b4ac110e8032dca126,
            vs: 0x37459dc63db143cbef86ae9b0393cd16b181b1d9ac561fced18c23035f290da2
        });

        sortedGuardianSignatures[2] = MintSecurity.Signature({
            r: 0x56657f42c6e54e0e03b0a2f0553ac5035971346b82029b0138e256e0255f4cfe,
            vs: 0xf0f59e5b4b8fb5b3accac5b786403380c79208337d0543dccceca5885963fdc8
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x0a323c499c5f3ba1508119b3d29ee063c26a3312dad38dda7912f4a34a10aab7,
            vs: 0x7620506989779ce6e5ea47624de9d3dfd9d83411174178e8d7aab83793fe75f8
        });

        _mintSecurity.mint(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );
    }

    function testFailMint3() public {
        address token = address(_obBTC);
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        uint256 stakingOutputIdx = 0;
        uint256 inclusionHeight = 2865235;
        uint256 stakingAmount = 120000000;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](2);

        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0x2baf05520e83bc494187cf71f9c343f82002e2346a0541b4ac110e8032dca126,
            vs: 0x37459dc63db143cbef86ae9b0393cd16b181b1d9ac561fced18c23035f290da2
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x56657f42c6e54e0e03b0a2f0553ac5035971346b82029b0138e256e0255f4cfe,
            vs: 0xf0f59e5b4b8fb5b3accac5b786403380c79208337d0543dccceca5885963fdc8
        });

        _mintSecurity.mint(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );
    }

    function testMint4() public {
        vm.prank(address(_dao));
        _mintSecurity.setGuardianQuorum(2);
        address token = address(_obBTC);
        bytes32 txHash = 0x2c8c452919c6f1d89dec39215926ac4b1e1e258eff8d3d3019120986a76a738a;
        address destAddr = 0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8;
        uint256 stakingOutputIdx = 0;
        uint256 inclusionHeight = 2865235;
        uint256 stakingAmount = 120000000;
        MintSecurity.Signature[] memory sortedGuardianSignatures = new MintSecurity.Signature[](2);

        sortedGuardianSignatures[0] = MintSecurity.Signature({
            r: 0x2baf05520e83bc494187cf71f9c343f82002e2346a0541b4ac110e8032dca126,
            vs: 0x37459dc63db143cbef86ae9b0393cd16b181b1d9ac561fced18c23035f290da2
        });

        sortedGuardianSignatures[1] = MintSecurity.Signature({
            r: 0x56657f42c6e54e0e03b0a2f0553ac5035971346b82029b0138e256e0255f4cfe,
            vs: 0xf0f59e5b4b8fb5b3accac5b786403380c79208337d0543dccceca5885963fdc8
        });

        _mintSecurity.mint(
            token, txHash, destAddr, stakingOutputIdx, inclusionHeight, stakingAmount, sortedGuardianSignatures
        );
    }

    function testFailRequestWithdraws() public {
        testMint();
        bytes memory _to = bytes("0xd6027dfc74fa9b2cffb447ee1b372ed6ba45ae615992b54a6fb3b11cb6e3a491");
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _obeliskNetwork.requestWithdrawals(address(_obBTC), 10000, _to);
    }

    function testRequestWithdraws() public {
        testMint();
        bytes memory _to = bytes("0xd6027dfc74fa9b2cffb447ee1b372ed6ba45ae615992b54a6fb3b11cb6e3a491");
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _obBTC.approve(address(_obeliskNetwork), 10000);

        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _obeliskNetwork.requestWithdrawals(address(_obBTC), 10000, _to);
    }

    function testClaimWithdrawals() public {
        testRequestWithdraws();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[] (1);
        _requestIds[0] = 0;
        _obeliskNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testFailClaimWithdrawals() public {
        testRequestWithdraws();

        uint256[] memory _requestIds = new uint256[] (1);
        _requestIds[0] = 0;
        _obeliskNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }
}
