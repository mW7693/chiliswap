pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract ChiliBar is ERC20("ChiliBar", "xCHILI"){
    using SafeMath for uint256;
    IERC20 public chili;

    constructor(IERC20 _chili) public {
        chili = _chili;
    }

    // Enter the bar. Pay some CHILIs. Earn some shares.
    function enter(uint256 _amount) public {
        uint256 totalChili = chili.balanceOf(address(this));
        uint256 totalShares = totalSupply();
        if (totalShares == 0 || totalChili == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 what = _amount.mul(totalShares).div(totalChili);
            _mint(msg.sender, what);
        }
        chili.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your CHILIs.
    function leave(uint256 _share) public {
        uint256 totalShares = totalSupply();
        uint256 what = _share.mul(chili.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        chili.transfer(msg.sender, what);
    }
}