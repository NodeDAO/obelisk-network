// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";
import "src/core/ObeliskCustody.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ObeliskCustodyTest is Test {
    address _dao = address(1000);
    address _ownerAddr = address(1001);

    ObeliskCustody public obeliskCustody;

    function setUp() public {
        address _obeliskCustodyImple = address(new ObeliskCustody());

        obeliskCustody = ObeliskCustody(payable(new ERC1967Proxy(_obeliskCustodyImple, "")));

        console.log("=====obeliskCustody=====", address(obeliskCustody));

        string[] memory marks = new string[](1);
        string[] memory btcAddrs = new string[](1);
        marks[0] = "mpc";
        btcAddrs[0] = "bc1qpde26qq28svk87knnnxa2vuucnsql40ec4522s";
        obeliskCustody.initialize(_ownerAddr, _dao, marks, btcAddrs);
    }

    function testGetCustodyAddrInfo() public view {
        ObeliskCustody.AddrInfo[] memory _addrInfos = obeliskCustody.getCustodyAddrInfo();
        for (uint256 i = 0; i < _addrInfos.length; ++i) {
            console.log(i, "====mark====", _addrInfos[i].mark);
            console.log(i, "====btcAddr====", _addrInfos[i].btcAddr);
        }
    }

    function testFailAddCustodyAddr() public {
        obeliskCustody.addCustodyAddr("mpc2", "bc1q5jz8c0g625u5yydym9ksexqz84g39sr76lnp0f");
    }

    function testFailAddCustodyAddr2() public {
        vm.prank(_dao);
        obeliskCustody.addCustodyAddr("", "bc1q5jz8c0g625u5yydym9ksexqz84g39sr76lnp0f");
    }

    function testFailAddCustodyAddr3() public {
        vm.prank(_dao);
        obeliskCustody.addCustodyAddr("mpc2", "");
    }

    function testAddCustodyAddr() public {
        vm.prank(_dao);
        obeliskCustody.addCustodyAddr("mpc2", "bc1q5jz8c0g625u5yydym9ksexqz84g39sr76lnp0f");
        testGetCustodyAddrInfo();
    }

    function testFailRemoveCustodyAddr() public {
        obeliskCustody.removeCustodyAddr(1);
    }

    function testFailRemoveCustodyAddr2() public {
        vm.prank(_dao);
        obeliskCustody.removeCustodyAddr(1);
    }

    function testRemoveCustodyAddr() public {
        vm.prank(_dao);
        obeliskCustody.removeCustodyAddr(0);
        console.log("========testRemoveCustodyAddr==========");
        testGetCustodyAddrInfo();
    }

    function testRemoveCustodyAddr2() public {
        testAddCustodyAddr();
        vm.prank(_dao);
        obeliskCustody.removeCustodyAddr(0);
        console.log("========testRemoveCustodyAddr2==========");
        testGetCustodyAddrInfo();
    }
}
