// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20PresetMinterPauserCapped.sol";


contract MyToken is ERC20PresetMinterPauserCapped ("MyToken", "MTK", 10000){
    
}