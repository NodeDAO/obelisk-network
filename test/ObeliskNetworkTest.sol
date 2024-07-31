// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "src/core/ObeliskNetwork.sol";
import "src/core/MintSecurity.sol";
import "src/core/StrategyManager.sol";
import "src/interfaces/IBaseToken.sol";
import "src/tokens/OBBTC.sol";
import "src/tokens/NBTCB2.sol";
import "src/tokens/NBTCBBL.sol";
import "src/core/ObeliskNetwork.sol";
import "src/strategies/DefiStrategy.sol";
import "src/core/MintSecurity.sol";
import "src/core/StrategyManager.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";
import "src/interfaces/IObeliskNetwork.sol";
import "src/modules/WithdrawalRequest.sol";
import "forge-std/console.sol";


contract ObeliskNetworkTest is Test, Script {
    
    address _obeliskNetworkImple = address(new ObeliskNetwork());
    ObeliskNetwork _obeliskNetwork = ObeliskNetwork(payable(new ERC1967Proxy(_obeliskNetworkImple, "")));
    StrategyManager public strategyManager;
    IBaseToken public ibaseToken;
    
    OBBTC obBTC = new OBBTC(address(_obeliskNetwork));

    address _dao = vm.addr(1) ;
    address user1 = vm.addr(5);
    address user2 = vm.addr(6);
    address  newBlackListAdmin  = vm.addr(7);
    address _mintSecurityImple = address(new MintSecurity());
    MintSecurity _mintSecurity = MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));


    address public testFrom;
    address public testTo;
    uint256 public testRequestId;
    uint256 public testRequestAmount;
    uint256 public testRecoveryDelayBlocks;

   function setUp() public {
        console.log("=====_obeliskNetwork=====", address(_obeliskNetwork));
        console.log("=====obBTC=====", address(obBTC));
        console.log("=====mintSecurity=====", address(_mintSecurity));

        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(obBTC);
        _obeliskNetwork.initialize(_dao, _dao, _dao, address(_mintSecurity), _tokenAddrs);
        _mintSecurity.initialize(_dao, _dao, address(_obeliskNetwork));
   }

function testMintFailures() public {
    // Test for minting from an unknown/unauthorized address
        address unknownAddress = address(0x1245);
        vm.expectRevert(Errors.PermissionDenied.selector);
        vm.prank( unknownAddress);
        IObeliskNetwork(_obeliskNetwork).mint(address(obBTC), address(0x1234), 10 ether );

    // Test for minting an unsupported asset
        address unsupportedAsset = address(0x5678);
        vm.expectRevert(Errors.AssetNotSupported.selector);
        vm.deal( address(_mintSecurity), 200 ether) ;
        vm.deal( address(0x1234), 200 ether) ;
        vm.prank( address(_mintSecurity));
        IObeliskNetwork(_obeliskNetwork).mint(unsupportedAsset, address(0x1234), 10 ether );
        
    // Test for minting to the zero address
        vm.expectRevert(Errors.AssetNotSupported.selector);
        vm.prank(address(_mintSecurity));
        IObeliskNetwork(_obeliskNetwork).mint(address(0), address(0x1234), 10 ether);

    // Test for minting zero amount
        vm.prank(address(_mintSecurity));
        IObeliskNetwork(_obeliskNetwork).mint(address(obBTC), address(0x1234), 0);

    // Test for minting a paused asset
        vm.prank(_dao);
        _obeliskNetwork.setAssetStatus(address(obBTC), true) ;
        vm.expectRevert(Errors.AssetPaused.selector);
        vm.prank(address(_mintSecurity));
        IObeliskNetwork(_obeliskNetwork).mint(address(obBTC), address(0x1234), 10 ether);

        vm.prank(_dao);
        _obeliskNetwork.setAssetStatus(address(obBTC), false) ;

        // Test successful minting
        vm.prank(address(_mintSecurity));
        IObeliskNetwork(_obeliskNetwork).mint(address(obBTC), address(0x1234), 10 ether );
        assertEq(IBaseToken(obBTC).balanceOf(address(0x1234)), 10 ether);
        
        // Test minting a supported asset
        vm.prank(address(_mintSecurity));
        IObeliskNetwork(_obeliskNetwork).mint(address(obBTC), address(0x5678), 20 ether);
        assertEq(IBaseToken(obBTC).balanceOf(address(0x5678)), 20 ether);
        
    }

function testRequestWithdrawals() public {
    vm.prank(address(_mintSecurity));
    IObeliskNetwork(_obeliskNetwork).mint(address(obBTC), user1, 200 * 10**18 );
    assertEq(IBaseToken(obBTC).balanceOf( user1), 200 * 10**18 );
    vm.startPrank(user1);
    IBaseToken(obBTC).approve(address(_obeliskNetwork), 100 * 10**18); // Set the allowance on the obBTC contract
    _obeliskNetwork.requestWithdrawals(address(obBTC), 100 * 10**18, abi.encodePacked(user1));
    // Check if user1 received the correct amount
    assertEq(IBaseToken(obBTC).balanceOf( user1), 100 * 10**18 );
    vm.stopPrank();

    vm.prank(address(_mintSecurity));
    IObeliskNetwork(_obeliskNetwork).mint(address(obBTC), user2, 300 * 10**18 );
    assertEq(IBaseToken(obBTC).balanceOf( user2), 300 * 10**18 );
    vm.startPrank(user2);
    IBaseToken(obBTC).approve(address(_obeliskNetwork), 150 * 10**18); // Set the allowance on the obBTC contract
    _obeliskNetwork.requestWithdrawals(address(obBTC), 150 * 10**18, abi.encodePacked(user2));
    // Check if user2 received the correct amount
    assertEq(IBaseToken(obBTC).balanceOf( user2), 150 * 10**18 );
    vm.stopPrank();
}

function testAddAsset() public {
    vm.prank(_dao);
    _obeliskNetwork.addAsset(address(obBTC));
    uint256 initialLength = _obeliskNetwork.getAssetList().length;
    address[] memory assetListAfterAdd = _obeliskNetwork.getAssetList();
    bool obBTCExistsAfterAdd = false;
    for (uint256 i = 0; i < assetListAfterAdd.length; i++) {
        if (assetListAfterAdd[i] == address(obBTC)) {
            obBTCExistsAfterAdd = true;
            break;
        }
    }
    assert(obBTCExistsAfterAdd);


    vm.prank(_dao);
    _obeliskNetwork.removeAsset(address(obBTC));
    address[] memory assetListAfterRemove = _obeliskNetwork.getAssetList();
    bool obBTCExistsAfterRemove = false;
    for (uint256 i = 0; i < assetListAfterRemove.length; i++) {
        if (assetListAfterRemove[i] == address(obBTC)) {
            obBTCExistsAfterRemove = true;
            break;
        }
    }
    uint256 finalLength = _obeliskNetwork.getAssetList().length;
    assert(finalLength == initialLength - 1);
}

function testBulkClaimWithdrawalsInvalidLength() public {
        // Set up the test environment
        address[] memory receivers = new address[](2);
        receivers[0] = user1;
        receivers[1] = user2;

        uint256[][] memory requestIds = new uint256[][](1);
        requestIds[0] = new uint256[](1);
        requestIds[0][0] = 1;

        // Call the bulkClaimWithdrawals function with an invalid length
        vm.expectRevert(Errors.InvalidLength.selector);
        _obeliskNetwork.bulkClaimWithdrawals(receivers, requestIds);
    }

    struct RecoveryInfo {
        address from;
        address to;
        address token;
        uint32 executed;
        uint96 requestHeight;
        uint128 requestAmount;
    }

    RecoveryInfo[] public recoveryQueue;

    function getUserRecoverys(address _receiver) public view returns (RecoveryInfo[] memory) {
        uint256 counts = 0;
        for (uint256 i = 0; i < recoveryQueue.length; ++i) {
            if (recoveryQueue[i].to == _receiver) {
                counts++;
            }
        }

        RecoveryInfo[] memory userRecoverys = new RecoveryInfo[](counts);
        uint256 index = 0;
        for (uint256 i = 0; i < recoveryQueue.length; ++i) {
            if (recoveryQueue[i].to == _receiver) {
                userRecoverys[index] = recoveryQueue[i];
            }
        }

        return userRecoverys;
    }

    function testSetBlackListAdmin() public {
        // Verify the initial state
        assertEq(_obeliskNetwork.blackListAdmin(),_dao );

        // Attempt to set the new BlackList admin from a non-DAO address
        vm.prank(address(0x9876));
        vm.expectRevert(abi.encodeWithSelector(Errors.PermissionDenied.selector));
        _obeliskNetwork.setBlackListAdmin(newBlackListAdmin);

        // Set the new BlackList admin (only DAO can do this)
        vm.prank(_dao);
        _obeliskNetwork.setBlackListAdmin(newBlackListAdmin);

        // Verify the new BlackList admin
        assertEq(_obeliskNetwork.blackListAdmin(), newBlackListAdmin);
    }


    function testFundRecovery() public {
        testFrom = address(0x1234567890abcdef); // Replace with a valid Ethereum address
        testTo = address(0xfedcba9876543210); // Replace with a valid Ethereum address
        testRequestAmount = 1 * 10**17; // Replace with a valid request amount
        testRequestId = 0; // Replace with a valid request ID

        vm.prank(address(_mintSecurity));
        IObeliskNetwork(_obeliskNetwork).mint(address(obBTC), testFrom, 1 * 10**18 );

        // Initiate the fund recovery (only DAO can do this)
        vm.prank(_dao);
        _obeliskNetwork.initiateFundRecovery(testFrom, testTo, address(obBTC), testRequestAmount);
        FundRecovery.RecoveryInfo  memory _recoveryInfo = _obeliskNetwork.getUserRecoverys(testTo)[0] ;
        // Verify the initial state
        assertEq(obBTC.balanceOf(testFrom), 1 * 10**18);
        assertEq(obBTC.balanceOf(testTo), 0 );
        // Assert that the first element of the recoveryInfo array matches the expected value
        assertEq(_recoveryInfo.from, testFrom);
        assertEq(_recoveryInfo.to, testTo);
        assertEq(_recoveryInfo.requestAmount, testRequestAmount);
        assertEq(_recoveryInfo.executed, 0);
        // Fast-forward the block number to satisfy the recovery delay condition
        vm.roll(block.number + _obeliskNetwork.recoveryDelayBlocks());

        // Execute the fund recovery (only DAO can do this)
        vm.prank(_dao);
        _obeliskNetwork.executeFundRecovery(testRequestId);

        // Verify the final state
        assertEq(obBTC.balanceOf(testFrom), 1 * 10**18 - testRequestAmount);
        assertEq(obBTC.balanceOf(testTo), testRequestAmount);
        FundRecovery.RecoveryInfo memory afterRecoveryInfos = _obeliskNetwork.getUserRecoverys(testTo)[0] ;
        assertEq(afterRecoveryInfos.executed, 1);  
    }

}
