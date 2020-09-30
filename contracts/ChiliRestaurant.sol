pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract ChiliRestaurant {
    using SafeMath for uint256;
    event Enter(address indexed user, uint256 amount);
    event Leave(address indexed user, uint256 amount);

    IERC20 public chili;

    uint256 public reductionPerBlock;
    uint256 public multiplier;
    uint256 public lastMultiplerProcessBlock;

    uint256 public accChiliPerShare;
    uint256 public ackChiliBalance;
    uint256 public totalShares;

    struct UserInfo {
        uint256 amount; // SUSHI stake amount
        uint256 share;
        uint256 rewardDebt;
    }

    mapping (address => UserInfo) public userInfo;

    constructor(IERC20 _chili, uint256 _reductionPerBlock) public {
        chili = _chili;
        reductionPerBlock = _reductionPerBlock; // Use 999999390274979584 for 10% per month
        multiplier = 1e18; // Should be good for 20 years
        lastMultiplerProcessBlock = block.number;
    }

    // Clean the restaurant. Called whenever someone enters or leaves.
    function cleanup() public {
        // Update multiplier
        uint256 reductionTimes = block.number.sub(lastMultiplerProcessBlock);
        uint256 fraction = 1e18;
        uint256 acc = reductionPerBlock;
        while (reductionTimes > 0) {
            if (reductionTimes & 1 != 0) {
                fraction = fraction.mul(acc).div(1e18);
            }
            acc = acc.mul(acc).div(1e18);
            reductionTimes = reductionTimes / 2;
        }
        multiplier = multiplier.mul(fraction).div(1e18);
        lastMultiplerProcessBlock = block.number;
        // Update accChiliPerShare / ackChiliBalance
        if (totalShares > 0) {
            uint256 additionalChili = chili.balanceOf(address(this)).sub(ackChiliBalance);
            accChiliPerShare = accChiliPerShare.add(additionalChili.mul(1e12).div(totalShares));
            ackChiliBalance = ackChiliBalance.add(additionalChili);
        }
    }

    // Get user pending reward. May be outdated until someone calls cleanup.
    function getPendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        return user.share.mul(accChiliPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Enter the restaurant. Pay some SUSHIs. Earn some shares.
    function enter(uint256 _amount) public {
        cleanup();
        safeChiliTransfer(msg.sender, getPendingReward(msg.sender));
        chili.transferFrom(msg.sender, address(this), _amount);
        ackChiliBalance = ackChiliBalance.add(_amount);
        UserInfo storage user = userInfo[msg.sender];
        uint256 moreShare = _amount.mul(multiplier).div(1e18);
        user.amount = user.amount.add(_amount);
        totalShares = totalShares.add(moreShare);
        user.share = user.share.add(moreShare);
        user.rewardDebt = user.share.mul(accChiliPerShare).div(1e12);
        emit Enter(msg.sender, _amount);
    }

    // Leave the restaurant. Claim back your SUSHIs.
    function leave(uint256 _amount) public {
        cleanup();
        safeChiliTransfer(msg.sender, getPendingReward(msg.sender));
        UserInfo storage user = userInfo[msg.sender];
        uint256 lessShare = user.share.mul(_amount).div(user.amount);
        user.amount = user.amount.sub(_amount);
        totalShares = totalShares.sub(lessShare);
        user.share = user.share.sub(lessShare);
        user.rewardDebt = user.share.mul(accChiliPerShare).div(1e12);
        safeChiliTransfer(msg.sender, _amount);
        emit Leave(msg.sender, _amount);
    }

    // Safe chili transfer function, just in case if rounding error causes pool to not have enough SUSHIs.
    function safeChiliTransfer(address _to, uint256 _amount) internal {
        uint256 chiliBal = chili.balanceOf(address(this));
        if (_amount > chiliBal) {
            chili.transfer(_to, chiliBal);
            ackChiliBalance = ackChiliBalance.sub(chiliBal);
        } else {
            chili.transfer(_to, _amount);
            ackChiliBalance = ackChiliBalance.sub(_amount);
        }
    }
}