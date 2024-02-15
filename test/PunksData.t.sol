// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";

contract PunksDataTest is Test {
    /*//////////////////////////////////////////////////////////////
                                USER DEFINED
    //////////////////////////////////////////////////////////////*/
    uint16 internal constant PUNK_ID = 6969;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes internal palette;

    bytes[] internal layers;

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
        palette = loadBytes(bytes32(SLOT_PALETTE));
    }

    /*//////////////////////////////////////////////////////////////
                    TEST: CONSTRUCT IMAGES
    //////////////////////////////////////////////////////////////*/

    function test_construct_images() public {
        bytes memory pixels = buildPunkImage(PUNK_ID);
        emit log_bytes(pixels);

        writeLayers();
    }

    /*//////////////////////////////////////////////////////////////
                    TEST: EXPLANATION HELPERS
    //////////////////////////////////////////////////////////////*/

    function test_punks() public {
        uint8 cell = getCell(PUNK_ID);
        uint256 offset = getOffset(PUNK_ID);

        bytes memory punks = loadBytes(keccak256(abi.encode(cell, SLOT_PUNKS)));

        emit log_named_uint("cell", cell);
        emit log_named_uint("offset", offset);
        emit log_named_uint("punks.length", punks.length);

        bytes memory punkAssetPointers;
        for (uint256 i; i < 8; ++i) {
            punkAssetPointers = bytes.concat(punkAssetPointers, punks[offset + i]);
        }
        emit log_named_bytes("punk asset pointers", punkAssetPointers);
    }

    /*//////////////////////////////////////////////////////////////
                    LOGIC: IMAGE CONSTRUCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Adapeted `punkImage` function from CryptopunksData contract.
    /// @dev Saves pixels built for each layer in storage.
    function buildPunkImage(uint16 index) internal returns (bytes memory) {
        if (index >= 10000) revert PunkIndexTooHigh();

        uint8 cell = getCell(index);
        uint256 offset = getOffset(index);

        bytes memory punks = loadBytes(keccak256(abi.encode(cell, SLOT_PUNKS)));

        bytes memory pixels = new bytes(IMAGE_PIXEL_SIZE);
        for (uint256 j; j < 8; ++j) {
            uint8 assetKey = uint8(punks[offset + j]);
            if (assetKey > 0) {
                bytes memory asset = loadBytes(keccak256(abi.encode(assetKey, SLOT_ASSETS)));
                uint256 n = asset.length / 3;
                for (uint256 i; i < n; ++i) {
                    uint256[4] memory v = [
                        uint256(uint8(asset[i * 3]) & 0xF0) >> 4,
                        uint256(uint8(asset[i * 3]) & 0xF),
                        uint256(uint8(asset[i * 3 + 2]) & 0xF0) >> 4,
                        uint256(uint8(asset[i * 3 + 2]) & 0xF)
                    ];
                    for (uint256 dx; dx < 2; ++dx) {
                        for (uint256 dy; dy < 2; ++dy) {
                            uint256 p = ((2 * v[1] + dy) * 24 + (2 * v[0] + dx)) * 4;
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c =
                                    composite(asset[i * 3 + 1], pixels[p], pixels[p + 1], pixels[p + 2], pixels[p + 3]);
                                pixels[p] = c[0];
                                pixels[p + 1] = c[1];
                                pixels[p + 2] = c[2];
                                pixels[p + 3] = c[3];
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0;
                                pixels[p + 1] = 0;
                                pixels[p + 2] = 0;
                                pixels[p + 3] = 0xFF;
                            }
                        }
                    }
                }
                layers.push(pixels);
            }
        }
        return pixels;
    }

    /// @notice Writes stored punk asset layers to an output file.
    function writeLayers() internal {
        string memory s;
        for (uint256 i; i < layers.length; ++i) {
            if (i != 0) {
                s = string.concat(s, string.concat("\n", vm.toString(layers[i])));
            } else {
                s = string.concat(s, vm.toString(layers[i]));
            }
        }
        vm.writeFile("./analysis/output.txt", s);
    }

    /// @notice Adapted composite function from CryptopunksData contract.
    function composite(bytes1 index, bytes1 yr, bytes1 yg, bytes1 yb, bytes1 ya) internal view returns (bytes4 rgba) {
        uint256 x = uint256(uint8(index)) * 4;
        uint8 xAlpha = uint8(palette[x + 3]);

        if (xAlpha == 0xFF) {
            rgba = bytes4(
                uint32(
                    (uint256(uint8(palette[x])) << 24) | (uint256(uint8(palette[x + 1])) << 16)
                        | (uint256(uint8(palette[x + 2])) << 8) | xAlpha
                )
            );
        } else {
            uint64 key = (uint64(uint8(palette[x])) << 56) | (uint64(uint8(palette[x + 1])) << 48)
                | (uint64(uint8(palette[x + 2])) << 40) | (uint64(xAlpha) << 32) | (uint64(uint8(yr)) << 24)
                | (uint64(uint8(yg)) << 16) | (uint64(uint8(yb)) << 8) | (uint64(uint8(ya)));

            rgba = bytes4(uint32(uint256(vm.load(punkData, keccak256(abi.encode(key, SLOT_COMPOSITES))))));
        }
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
            revert CastToBytesFailed(length);
        }
    }

    error CastToBytesFailed(uint256 length);
    error PunkIndexTooHigh();
}
