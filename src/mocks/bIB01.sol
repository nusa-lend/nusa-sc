// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract bIB01 is ERC20, Ownable {
    constructor() ERC20("Backed IB01 $ Treasury Bond 0-1yr", "bIB01") Ownable(msg.sender) {}

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) public {
        _burn(_from, _amount);
    }
}
