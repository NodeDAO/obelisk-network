// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/tokens/OBTC.sol";
import "src/tokens/OLTC.sol";
import "src/tokens/OYBTCB2.sol";
import "src/tokens/OYBTCBBN.sol";
import {TestToken, TestToken2} from "test/TestToken.sol";
import "src/core/ObeliskNetwork.sol";
import "src/strategies/DefiStrategy.sol";
import "src/core/MintSecurity.sol";
import "src/core/MintStrategy.sol";
import "src/core/StrategyManager.sol";
import "src/interfaces/IBaseStrategy.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ObeliskNetworkTest is Test {
    address _dao = address(1000);
    address _ownerAddr = address(1001);
    address _blackListAdmin = address(1003);
    address _fundManager = address(1004);

    OBTC public _oBTC;
    ObeliskNetwork public _obeliskNetwork;
    StrategyManager public _strategyManager;
    MintSecurity public _mintSecurity;
    DefiStrategy public _defiStrategyB2;
    DefiStrategy public _defiStrategyBBL;
    MintStrategy public _mintStrategy;
    TestToken public _testBTC;
    MintStrategy public _mintStrategy2;
    TestToken2 public _testBTC2;

    function setUp() public {
        address _obeliskNetworkImple = address(new ObeliskNetwork());
        _obeliskNetwork = ObeliskNetwork(payable(new ERC1967Proxy(_obeliskNetworkImple, "")));

        console.log("=====obeliskNetwork=====", address(_obeliskNetwork));

        _oBTC = new OBTC(address(_obeliskNetwork));

        console.log("=====obBTC=====", address(_oBTC));

        address _mintSecurityImple = address(new MintSecurity());
        _mintSecurity = MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));

        console.log("=====mintSecurity=====", address(_mintSecurity));

        address _strategyManagerImple = address(new StrategyManager());
        _strategyManager = StrategyManager(payable(new ERC1967Proxy(_strategyManagerImple, "")));

        console.log("=====strategyManager=====", address(_strategyManager));

        address _mintStrategyImple = address(new MintStrategy());
        _mintStrategy = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));

        _testBTC = new TestToken("test BTC", "tBTC", _dao);
        _mintStrategy.initialize(
            _ownerAddr, _dao, address(_obeliskNetwork), address(_testBTC), address(_oBTC), 50400
        );

        _mintStrategy2 = MintStrategy(payable(new ERC1967Proxy(_mintStrategyImple, "")));
        _testBTC2 = new TestToken2("test BTC 2", "tBTC2", _dao);
        _mintStrategy2.initialize(
            _ownerAddr, _dao, address(_obeliskNetwork), address(_testBTC2), address(_oBTC), 50400
        );

        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(_oBTC);
        address[] memory _mintStrategies = new address[](2);
        _mintStrategies[0] = address(_mintStrategy);
        _mintStrategies[1] = address(_mintStrategy2);
        _obeliskNetwork.initialize(
            _ownerAddr, _dao, _blackListAdmin, address(_mintSecurity), _tokenAddrs, _mintStrategies
        );

        _mintSecurity.initialize(_ownerAddr, _dao, address(_obeliskNetwork));
        // MINT_MESSAGE_PREFIX 0x5706b75259dd61ada5d917cc9b0e797d76b00ca645bc55beb09d4c8ff153ec16
        console.logBytes32(_mintSecurity.MINT_MESSAGE_PREFIX());

        address[] memory _guardians = new address[](3);
        _guardians[0] = 0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc;
        _guardians[1] = 0xc214f4fBb7C9348eF98CC09c83d528E3be2b63A5;
        _guardians[2] = 0xd7189759502ec8bb475e707aCB1C6A4D210e0214;
        vm.prank(address(_dao));
        _mintSecurity.addGuardians(_guardians, 3);

        address[] memory _strategies = deployStrategys();
        _strategyManager.initialize(_ownerAddr, _dao, _strategies);
    }

    function deployStrategys() internal returns (address[] memory) {
        address _defiStrategyImple = address(new DefiStrategy());
        _defiStrategyB2 = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        _defiStrategyBBL = DefiStrategy(payable(new ERC1967Proxy(_defiStrategyImple, "")));
        console.log("=====defiStrategyB2=====", address(_defiStrategyB2));
        console.log("=====defiStrategyBBL=====", address(_defiStrategyBBL));
        OYBTCB2 nBTCb2 = new OYBTCB2(address(_defiStrategyB2));
        OYBTCBBN nBTCbbl = new OYBTCBBN(address(_defiStrategyBBL));
        console.log("=====nBTCb2=====", address(nBTCb2));
        console.log("=====nBTCbbl=====", address(nBTCbbl));

        _defiStrategyB2.initialize(
            _ownerAddr,
            _dao,
            address(_strategyManager),
            _fundManager,
            10000,
            10000000000000,
            address(_oBTC),
            address(nBTCb2)
        );
        _defiStrategyBBL.initialize(
            _ownerAddr,
            _dao,
            address(_strategyManager),
            _fundManager,
            10000,
            10000000000000,
            address(_oBTC),
            address(nBTCbbl)
        );

        address[] memory _strategies = new address[](2);
        _strategies[0] = address(_defiStrategyB2);
        _strategies[1] = address(_defiStrategyBBL);
        return _strategies;
    }

    function testMint() public {
        address token = address(_oBTC);
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

        assertEq(_oBTC.balanceOf(destAddr), stakingAmount);
    }

    function testFailMint() public {
        vm.prank(address(_dao));
        _mintSecurity.pause();
        testMint();
    }

    function testFailMint2() public {
        address token = address(_oBTC);
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
        address token = address(_oBTC);
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
        address token = address(_oBTC);
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
        _obeliskNetwork.requestWithdrawals(0x000000000000000000000000000000000000000b, address(_oBTC), 10000, _to);
    }

    function testRequestWithdraws() public {
        testMint();
        bytes memory _to = bytes("0xd6027dfc74fa9b2cffb447ee1b372ed6ba45ae615992b54a6fb3b11cb6e3a491");
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _oBTC.approve(address(_obeliskNetwork), 10000);

        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _obeliskNetwork.requestWithdrawals(0x000000000000000000000000000000000000000b, address(_oBTC), 10000, _to);
    }

    function testFailPauseRequestWithdraws() public {
        vm.prank(address(_dao));
        _obeliskNetwork.pause();

        testRequestWithdraws();
    }

    function testClaimWithdrawals() public {
        testRequestWithdraws();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _obeliskNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testFailPauseClaimWithdrawals() public {
        testRequestWithdraws();

        vm.prank(address(_dao));
        _obeliskNetwork.pause();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _obeliskNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testFailClaimWithdrawals() public {
        testRequestWithdraws();

        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _obeliskNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testFailClaimWithdrawals2() public {
        testRequestWithdraws();
        testAddBlackList();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _obeliskNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testClaimWithdrawals2() public {
        testRequestWithdraws();
        testAddBlackList();
        testRemoveBlackList();

        vm.roll(50500);
        uint256[] memory _requestIds = new uint256[](1);
        _requestIds[0] = 0;
        _obeliskNetwork.claimWithdrawals(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8, _requestIds);
    }

    function testAddBlackList() public {
        vm.prank(_blackListAdmin);
        _obeliskNetwork.addBlackList(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        assertTrue(_obeliskNetwork.isBlackListed(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8));
    }

    function testRemoveBlackList() public {
        vm.prank(_blackListAdmin);
        _obeliskNetwork.removeBlackList(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        assertTrue(!_obeliskNetwork.isBlackListed(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8));
    }

    function testFailSetBlackListAdmin() public {
        _obeliskNetwork.setBlackListAdmin(address(1));
    }

    function testSetBlackListAdmin() public {
        vm.prank(_dao);
        _obeliskNetwork.setBlackListAdmin(address(1));
        assertEq(_obeliskNetwork.blackListAdmin(), address(1));
    }

    function testAddAsset() public returns (address) {
        OLTC _oltc = new OLTC(address(_obeliskNetwork));
        vm.prank(_dao);
        _obeliskNetwork.addAsset(address(_oltc));
        return address(_oltc);
    }

    function testFailAddAsset() public {
        vm.prank(_dao);
        _obeliskNetwork.addAsset(address(1));
    }

    function testFailAddAsset2() public {
        OLTC _oltc = new OLTC(address(_obeliskNetwork));
        _obeliskNetwork.addAsset(address(_oltc));
    }

    function testFailAddAsset3() public {
        address _oltc = testAddAsset();
        vm.prank(_dao);
        _obeliskNetwork.addAsset(address(_oltc));
    }

    function testGetAssetList() public {
        address _oltc = testAddAsset();
        address[] memory assetList = _obeliskNetwork.getAssetList();

        assertEq(assetList.length, 2);
        assertEq(assetList[0], address(_oBTC));
        assertEq(assetList[1], _oltc);
    }

    function testRemoveAsset() public {
        address _oltc = testAddAsset();
        vm.prank(_dao);
        _obeliskNetwork.removeAsset(address(_oltc));
        address[] memory assetList = _obeliskNetwork.getAssetList();
        assertEq(assetList.length, 1);
        assertEq(assetList[0], address(_oBTC));
    }

    function testSetAssetStatus() public {
        address _oltc = testAddAsset();
        assertTrue(!_obeliskNetwork.assetPaused(_oltc));
        vm.prank(_dao);
        _obeliskNetwork.setAssetStatus(address(_oltc), false);
        assertTrue(!_obeliskNetwork.assetPaused(_oltc));
        vm.prank(_dao);
        _obeliskNetwork.setAssetStatus(address(_oltc), true);
        assertTrue(_obeliskNetwork.assetPaused(_oltc));
        vm.prank(_dao);
        _obeliskNetwork.removeAsset(address(_oltc));
        address[] memory assetList = _obeliskNetwork.getAssetList();
        assertEq(assetList.length, 1);
        assertEq(assetList[0], address(_oBTC));
        assertTrue(!_obeliskNetwork.assetPaused(_oltc));
    }

    function testSetWithdrawalDelayBlocks() public {
        assertEq(_obeliskNetwork.withdrawalDelayBlocks(), 50400);
        vm.prank(_dao);
        _obeliskNetwork.setWithdrawalDelayBlocks(20);
        assertEq(_obeliskNetwork.withdrawalDelayBlocks(), 20);
    }

    function testFailSetWithdrawalDelayBlocks() public {
        vm.prank(_dao);
        _obeliskNetwork.setWithdrawalDelayBlocks(72001);
    }

    function testGetGuardianQuorum() public {
        assertEq(_mintSecurity.getGuardianQuorum(), 3);
        vm.prank(_dao);
        _mintSecurity.setGuardianQuorum(2);
        assertEq(_mintSecurity.getGuardianQuorum(), 2);
    }

    function testGetGuardians() public view {
        address[] memory _guardians = _mintSecurity.getGuardians();
        assertEq(_guardians[0], 0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc);
        assertEq(_guardians[1], 0xc214f4fBb7C9348eF98CC09c83d528E3be2b63A5);
        assertEq(_guardians[2], 0xd7189759502ec8bb475e707aCB1C6A4D210e0214);
        assertTrue(_mintSecurity.isGuardian(0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc));
        assertTrue(_mintSecurity.isGuardian(0xc214f4fBb7C9348eF98CC09c83d528E3be2b63A5));
        assertTrue(_mintSecurity.isGuardian(0xd7189759502ec8bb475e707aCB1C6A4D210e0214));
        assertEq(_mintSecurity.getGuardianIndex(0xF5ade6B61BA60B8B82566Af0dfca982169a470Dc), 0);
        assertEq(_mintSecurity.getGuardianIndex(0xc214f4fBb7C9348eF98CC09c83d528E3be2b63A5), 1);
        assertEq(_mintSecurity.getGuardianIndex(0xd7189759502ec8bb475e707aCB1C6A4D210e0214), 2);
        assertEq(_mintSecurity.getGuardianIndex(address(1)), -1);
    }

    function testFailAddGuardian() public {
        _mintSecurity.addGuardian(address(1), 4);
    }

    function testAddGuardian() public {
        vm.prank(_dao);
        _mintSecurity.addGuardian(address(1), 4);
        assertEq(_mintSecurity.getGuardianQuorum(), 4);
        assertEq(_mintSecurity.getGuardianIndex(address(1)), 3);
    }

    function testFailremoveGuardian() public {
        testAddGuardian();
        _mintSecurity.removeGuardian(address(1), 3);
    }

    function testFailremoveGuardian2() public {
        testAddGuardian();
        vm.prank(_dao);
        _mintSecurity.removeGuardian(address(2), 3);
    }

    function testremoveGuardian() public {
        testAddGuardian();
        vm.prank(_dao);
        _mintSecurity.removeGuardian(address(1), 3);
        assertEq(_mintSecurity.getGuardianQuorum(), 3);
        assertEq(_mintSecurity.getGuardianIndex(address(1)), -1);
    }

    function testGetStrategyList() public view {
        address[] memory strategyList = _strategyManager.getWhitelistedList();
        assertEq(strategyList.length, 2);
        assertEq(address(_defiStrategyB2), strategyList[0]);
        assertEq(address(_defiStrategyBBL), strategyList[1]);
    }

    function testAddStrategies() public {
        address[] memory _strategies = deployStrategys();
        assertEq(_strategyManager.isWhitelisted(_strategies[0]), false);
        assertEq(_strategyManager.isWhitelisted(_strategies[1]), false);

        vm.prank(_dao);
        _strategyManager.addWhitelisted(_strategies);
        assertEq(_strategyManager.isWhitelisted(_strategies[0]), true);
        assertEq(_strategyManager.isWhitelisted(_strategies[1]), true);
        address[] memory strategyList = _strategyManager.getWhitelistedList();
        assertEq(strategyList.length, 4);

        vm.prank(_dao);
        _strategyManager.removeWhitelisted(_strategies);
        assertEq(_strategyManager.isWhitelisted(_strategies[0]), false);
        assertEq(_strategyManager.isWhitelisted(_strategies[1]), false);
        strategyList = _strategyManager.getWhitelistedList();
        assertEq(strategyList.length, 2);
    }

    function testDeposit() public {
        testMint();
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _oBTC.approve(address(_defiStrategyB2), 100000);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _oBTC.approve(address(_defiStrategyBBL), 100000);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.deposit(address(_defiStrategyB2), 100000);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.deposit(address(_defiStrategyBBL), 100000);
        assertEq(_oBTC.balanceOf(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8), 120000000 - 100000 * 2);
    }

    function testFailDeposit() public {
        testMint();
        vm.prank(_fundManager);
        _defiStrategyBBL.setStrategyStatus(IBaseStrategy.StrategyStatus.Close, IBaseStrategy.StrategyStatus.Close);
        vm.prank(_fundManager);
        _defiStrategyB2.setStrategyStatus(IBaseStrategy.StrategyStatus.Close, IBaseStrategy.StrategyStatus.Close);

        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _oBTC.approve(address(_defiStrategyB2), 100000);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _oBTC.approve(address(_defiStrategyBBL), 100000);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.deposit(address(_defiStrategyB2), 100000);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.deposit(address(_defiStrategyBBL), 100000);
        assertEq(_oBTC.balanceOf(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8), 120000000 - 100000 * 2);
    }

    function testFailWithdrawal() public {
        testDeposit();
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.withdraw(address(_defiStrategyBBL), 100000);
    }

    function testWithdrawal() public {
        testDeposit();
        vm.prank(_fundManager);
        _defiStrategyBBL.setStrategyStatus(IBaseStrategy.StrategyStatus.Open, IBaseStrategy.StrategyStatus.Open);
        vm.prank(0x3535d10Fc0E85fDBC810bF828F02C9BcB7C2EBA8);
        _strategyManager.withdraw(address(_defiStrategyBBL), 100000);
    }

    function testTBTCDeposit() public {
        vm.prank(_dao);
        _testBTC.whiteListMint(10000000000, address(1));
        vm.prank(address(1));
        _testBTC.approve(address(_mintStrategy), 100000000);

        vm.prank(address(1));
        _obeliskNetwork.deposit(address(_mintStrategy), address(_oBTC), 100000000);

        assertEq(_testBTC.balanceOf(address(_mintStrategy)), 100000000);
        assertEq(_oBTC.balanceOf(address(1)), 100000000);
    }

    function testTBTCDeposit2() public {
        vm.prank(_dao);
        _testBTC2.whiteListMint(100000000000000000000, address(1));
        vm.prank(address(1));
        _testBTC2.approve(address(_mintStrategy2), 1000000000000000000);

        vm.prank(address(1));
        _obeliskNetwork.deposit(address(_mintStrategy2), address(_oBTC), 1000000000000000000);

        assertEq(_testBTC2.balanceOf(address(_mintStrategy2)), 1000000000000000000);
        assertEq(_oBTC.balanceOf(address(1)), 100000000);
    }
}
