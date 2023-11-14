// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

contract PunksDataTest is Test {
    /*//////////////////////////////////////////////////////////////
                                 USER DEFINED
    //////////////////////////////////////////////////////////////*/
    uint16 internal constant PUNK_ID = 35;

    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    address internal constant punkData = 0x16F5A35647D6F03D5D3da7b35409D65ba03aF3B2;

    uint256 internal constant SLOT_PALETTE = 0;
    uint256 internal constant SLOT_ASSETS = 1;
    uint256 internal constant SLOT_ASSET_NAMES = 2;
    uint256 internal constant SLOT_COMPOSITES = 3;
    uint256 internal constant SLOT_PUNKS = 4;
    uint256 internal constant IMAGE_PIXEL_SIZE = 2304;

    function setUp() public {
        vm.createSelectFork("mainnet");
    }
}
