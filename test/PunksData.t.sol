// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

contract PunksDataTest is Test {
    /*//////////////////////////////////////////////////////////////
                                USER DEFINED
    //////////////////////////////////////////////////////////////*/
    uint16 internal constant PUNK_ID = 35;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes internal palette;

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

    error Error_CastToBytes(uint256 length);

    function setUp() public {
        vm.createSelectFork("mainnet");
        palette = loadBytes(bytes32(SLOT_PALETTE));
    }

    /*//////////////////////////////////////////////////////////////
                    LOGIC: INDEXING
    //////////////////////////////////////////////////////////////*/

    /// @notice Retrieve the `punks` mapping key, referred to as cell in `CryptopunksData`.
    /// @param index The punk index.
    function getCell(uint16 index) internal pure returns (uint8) {
        return uint8(index / 100);
    }

    /// @notice Retrieves a pointer to encoded data for a given punk index.
    /// @param index The punk index.
    function getOffset(uint16 index) internal pure returns (uint256) {
        return uint256(index % 100) * 8;
    }

    /*//////////////////////////////////////////////////////////////
                    LOGIC: LOAD BYTES FROM STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Loads bytes (short and long) from a designated storage slot/s in `CryptopunksData`.
    /// Logic covered:
    /// - Short arrays (< 32 bytes)
    /// - Long arrays:
    ///   - length = 32 bytes
    ///   - length > 32 bytes:
    ///     - final slot length = 32 bytes
    ///     - final slot length < 32 bytes
    /// @param slot Storage slot for bytes -- ex: `palette`, `assets` or `punks` in `CryptopunksData`.
    function loadBytes(bytes32 slot) internal view returns (bytes memory) {
        bytes32 value = vm.load(punkData, slot);

        bytes memory cb;

        if (value >> (8 * 31) != 0) {
            // Retrieves `2 * length` from lowest byte
            uint256 len = (uint256(value) & (1 << 8) - 1);
            return castToBytes(len, value);
        } else {
            SlotData memory data = getLongArraySlotData(uint256(value));
            bytes32 hashedSlot = keccak256(abi.encodePacked(slot));

            if (data.numSlots > 1) {
                if (data.lastSlotLength < 32) {
                    for (uint256 i; i < data.numSlots; ++i) {
                        if (i == 0) {
                            cb = bytes.concat(cb, vm.load(punkData, hashedSlot));
                        } else if (i > 0 && i < data.numSlots - 1) {
                            cb = bytes.concat(cb, vm.load(punkData, bytes32(uint256(hashedSlot) + i)));
                        } else {
                            cb = bytes.concat(
                                cb,
                                castToBytes(
                                    data.lastSlotLength * 2, // 2 * length basis
                                    vm.load(punkData, bytes32(uint256(hashedSlot) + i))
                                )
                            );
                        }
                    }
                    return cb;
                } else {
                    for (uint256 i; i < data.numSlots; ++i) {
                        if (i > 0) {
                            cb = bytes.concat(cb, vm.load(punkData, bytes32(uint256(hashedSlot) + i)));
                        } else {
                            cb = bytes.concat(cb, vm.load(punkData, hashedSlot));
                        }
                    }
                    return cb;
                }
            } else {
                return bytes.concat(cb, vm.load(punkData, hashedSlot));
            }
        }
    }

    /// @notice Struct for holding long byte array slot data
    /// @param numSlots Number of 32-byte slots used
    /// @param lastSlotLength Length of the final slot -- 32 bytes if full slot is used.
    struct SlotData {
        uint256 numSlots;
        uint256 lastSlotLength;
    }

    /// @notice Retrieves storage information for a long bytes array.
    /// @param slotValue The value of the main slot for a long byte array
    /// @dev `slotValue` should return `length * 2 + 1`.
    function getLongArraySlotData(uint256 slotValue) internal pure returns (SlotData memory) {
        uint256 len = (slotValue - 1) / 2;
        uint256 mod = len % 32;

        SlotData memory data;

        if (mod != 0) {
            data.numSlots = (len / 32) + 1;
            data.lastSlotLength = mod;
        } else {
            data.numSlots = len / 32;
            data.lastSlotLength = 32;
        }
        return data;
    }

    /// @notice Converts a storage slot's value to bytes. Used for retrieving bytes from 32-byte slots
    /// that can be concatenated to existing byte arrays. Ex: short byte arrays and/or long byte arrays with
    /// a final slot less than 32 bytes.
    /// @param length Value of 2 * length of the byte array.
    /// @param slotValue The storage slot value - either main slot (short) or final slot (long).
    /// @dev Apologies for this abomination. Please advise if there is a better way.
    function castToBytes(uint256 length, bytes32 slotValue) internal pure returns (bytes memory) {
        if (length == 2) {
            return abi.encodePacked(bytes1(slotValue));
        } else if (length == 4) {
            return abi.encodePacked(bytes2(slotValue));
        } else if (length == 6) {
            return abi.encodePacked(bytes3(slotValue));
        } else if (length == 8) {
            return abi.encodePacked(bytes4(slotValue));
        } else if (length == 10) {
            return abi.encodePacked(bytes5(slotValue));
        } else if (length == 12) {
            return abi.encodePacked(bytes6(slotValue));
        } else if (length == 14) {
            return abi.encodePacked(bytes7(slotValue));
        } else if (length == 16) {
            return abi.encodePacked(bytes8(slotValue));
        } else if (length == 18) {
            return abi.encodePacked(bytes9(slotValue));
        } else if (length == 20) {
            return abi.encodePacked(bytes10(slotValue));
        } else if (length == 22) {
            return abi.encodePacked(bytes11(slotValue));
        } else if (length == 24) {
            return abi.encodePacked(bytes12(slotValue));
        } else if (length == 26) {
            return abi.encodePacked(bytes13(slotValue));
        } else if (length == 28) {
            return abi.encodePacked(bytes14(slotValue));
        } else if (length == 30) {
            return abi.encodePacked(bytes15(slotValue));
        } else if (length == 32) {
            return abi.encodePacked(bytes16(slotValue));
        } else if (length == 34) {
            return abi.encodePacked(bytes17(slotValue));
        } else if (length == 36) {
            return abi.encodePacked(bytes18(slotValue));
        } else if (length == 38) {
            return abi.encodePacked(bytes19(slotValue));
        } else if (length == 40) {
            return abi.encodePacked(bytes20(slotValue));
        } else if (length == 42) {
            return abi.encodePacked(bytes21(slotValue));
        } else if (length == 44) {
            return abi.encodePacked(bytes22(slotValue));
        } else if (length == 46) {
            return abi.encodePacked(bytes23(slotValue));
        } else if (length == 48) {
            return abi.encodePacked(bytes24(slotValue));
        } else if (length == 50) {
            return abi.encodePacked(bytes25(slotValue));
        } else if (length == 52) {
            return abi.encodePacked(bytes26(slotValue));
        } else if (length == 54) {
            return abi.encodePacked(bytes27(slotValue));
        } else if (length == 56) {
            return abi.encodePacked(bytes28(slotValue));
        } else if (length == 58) {
            return abi.encodePacked(bytes29(slotValue));
        } else if (length == 60) {
            return abi.encodePacked(bytes30(slotValue));
        } else if (length == 62) {
            return abi.encodePacked(bytes31(slotValue));
        } else {
            revert Error_CastToBytes(length);
        }
    }
}
