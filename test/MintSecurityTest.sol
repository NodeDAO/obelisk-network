// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "src/core/MintSecurity.sol";
import "src/core/ObeliskNetwork.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";
import "src/tokens/OBBTC.sol";
import "src/libraries/ECDSA.sol";

contract MintSecurityTest is Test {
    MintSecurity public mintSecurity;
    address _obeliskNetworkImple = address(new ObeliskNetwork());
    ObeliskNetwork _obeliskNetwork =
        ObeliskNetwork(payable(new ERC1967Proxy(_obeliskNetworkImple, "")));
    address public _owner = vm.addr(1);
    address _dao = vm.addr(2);
    address _mintSecurityImple = address(new MintSecurity());
    MintSecurity _mintSecurity =
        MintSecurity(payable(new ERC1967Proxy(_mintSecurityImple, "")));

    function setUp() public {
        // Set up the testing environment
        console.log("=====mintSecurity=====", address(_mintSecurity));
        OBBTC obBTC = new OBBTC(address(_obeliskNetwork));

        address[] memory _tokenAddrs = new address[](1);
        _tokenAddrs[0] = address(obBTC);
        _obeliskNetwork.initialize(
            _owner,
            _dao,
            _dao,
            address(_mintSecurity),
            _tokenAddrs
        );

        _mintSecurity.initialize(_owner, _dao, address(_obeliskNetwork));
    }

    function testInitialize() public {
        // Test that the contract is initialized correctly
        assertEq(_mintSecurity.owner(), _owner);
        assertEq(_mintSecurity.dao(), _dao);
        assertEq(_mintSecurity.obeliskNetwork(), address(_obeliskNetwork));
    }

    function testSetGuardianQuorum() public {
        // Test setting the guardian quorum
        uint256 newQuorum = 5;
        vm.prank(_dao);
        _mintSecurity.setGuardianQuorum(newQuorum);
        assertEq(_mintSecurity.getGuardianQuorum(), newQuorum);
    }

    function testAddGuardian() public {
        // Test adding a guardian
        address newGuardian = address(4);
        uint256 newQuorum = 1;
        vm.prank(_dao);
        _mintSecurity.addGuardian(newGuardian, newQuorum);
        assertTrue(_mintSecurity.isGuardian(newGuardian));
    }

    function testRemoveGuardian() public {
        // Test removing a guardian
        address guardianToRemove = address(4);
        uint256 newQuorum = 1;

        address[] memory guardiansToAdd = new address[](1); // Create a dynamic array with size 1
        guardiansToAdd[0] = guardianToRemove; // Assign the guardian to the first element

        vm.prank(_dao);
        _mintSecurity.addGuardians(guardiansToAdd, newQuorum); // Pass the dynamic array here

        vm.prank(_dao);
        _mintSecurity.removeGuardian(guardianToRemove, newQuorum);
        assertFalse(_mintSecurity.isGuardian(guardianToRemove));
    }

    function testCalcMsgHash() public {
        address token = address(1);
        bytes32 txHash = keccak256("txHash");
        address destAddr = address(2);
        uint256 stakingOutputIdx = 1;
        uint256 inclusionHeight = 2;
        uint256 stakingAmount = 3;

        // Generate the MINT_MESSAGE_PREFIX dynamically
        bytes32 prefix = keccak256(
            abi.encodePacked(
                keccak256("obelisk.MINT_MESSAGE_PREFIX"),
                block.chainid,
                address(_mintSecurity)
            )
        );

        bytes32 expectedMsgHash = keccak256(
            abi.encodePacked(
                prefix,
                txHash,
                token,
                destAddr,
                stakingOutputIdx,
                inclusionHeight,
                stakingAmount
            )
        );

        bytes32 actualMsgHash = _mintSecurity.calcMsgHash(
            token,
            txHash,
            destAddr,
            stakingOutputIdx,
            inclusionHeight,
            stakingAmount
        );

        assertEq(actualMsgHash, expectedMsgHash, "Msg hash mismatch");
    }

    function testTypeId() public {
        bytes32 expectedTypeId = keccak256("MintSecurity");
        bytes32 actualTypeId = _mintSecurity.typeId();

        assertEq(actualTypeId, expectedTypeId, "Type ID mismatch");
    }

    function testVersion() public {
        uint8 expectedVersion = 3;
        uint8 actualVersion = _mintSecurity.version();

        assertEq(actualVersion, expectedVersion, "Version mismatch");
    }

    function testPause() public {
        // test that pause can be called by the Dao
        vm.prank(address(_dao)); // set the msg.sender to the Dao address
        _mintSecurity.pause();
        assertTrue(_mintSecurity.paused(), "MintSecurity should be paused");

        // test that pause cannot be called by a non-Dao address
        vm.prank(address(this)); // set the msg.sender to the test contract address
        vm.expectRevert(Errors.PermissionDenied.selector);
        _mintSecurity.pause();
    }

    function testUnpause() public {
        // pause the contract first
        vm.prank(address(_dao));
        _mintSecurity.pause();
        assertTrue(_mintSecurity.paused(), "MintSecurity should be paused");

        // test that unpause can be called by the Dao
        vm.prank(address(_dao));
        _mintSecurity.unpause();
        assertFalse(_mintSecurity.paused(), "MintSecurity should be unpaused");

        // test that unpause cannot be called by a non-Dao address
        vm.prank(address(this));
        vm.expectRevert(Errors.PermissionDenied.selector);
        _mintSecurity.unpause();
    }
}
