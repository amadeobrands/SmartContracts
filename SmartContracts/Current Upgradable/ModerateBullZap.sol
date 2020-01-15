// Copyright (C) 2019, 2020 dipeshsukhani, nodarjonashi, toshsharma, suhailg

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

/**
 * WARNING: This is an upgradable contract. Be careful not to disrupt
 * the existing storage layout when making upgrades to the contract. In particular,
 * existing fields should not be removed and should not have their types changed.
 * The order of field declarations must not be changed, and new fields must be added
 * below all existing declarations.
 *
 * The base contracts and the order in which they are declared must not be changed.
 * New fields must not be added to base contracts (unless the base contract has
 * reserved placeholder fields for this purpose).
 *
 * See https://docs.zeppelinos.org/docs/writing_contracts.html for more info.
*/

pragma solidity ^0.5.0;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";


interface Invest2_sBTC {
    function LetsInvestin_sBTC(address payable _toWhomToIssue) external payable returns(uint);
}

interface Invest2_sETH {
    function LetsInvestin_sETH(address payable _toWhomToIssue) external payable returns(uint);
}



contract ModerateBullZap is Initializable {
    using SafeMath for uint;
    
    // state variables
    
    // - THESE MUST ALWAYS STAY IN THE SAME LAYOUT
    bool private stopped;
    address payable public owner;
    Invest2_sBTC public Invest2_sBTCContract;
    Invest2_sETH public Invest2_sETHContract;
    

    // circuit breaker modifiers
    modifier stopInEmergency {if (!stopped) _;}
    modifier onlyInEmergency {if (stopped) _;}
    modifier onlyOwner() {
        require(isOwner(), "you are not authorised to call this function");
        _;
    }
    
    function initialize(address _a1, address _a2) initializer public {
        stopped = false;
        owner = msg.sender;
        Invest2_sBTCContract = Invest2_sBTC(_a1);
        Invest2_sETHContract = Invest2_sETH(_a2);
    }

    // main function which will make the investments
    function LetsInvest(address payable _toWhomToIssue, uint _sBTCPercentage, uint _slippage) stopInEmergency public payable returns(uint) {
        require(_sBTCPercentage >= 0 || _sBTCPercentage <= 100, "wrong allocation");
        uint sBTCPortion = SafeMath.div(SafeMath.mul(msg.value,_sBTCPercentage),100);
        uint sETHPortion = SafeMath.sub(msg.value, sBTCPortion);
        require (SafeMath.sub(msg.value, SafeMath.add(sBTCPortion, sETHPortion))==0,"Cannot split incoming ETH appropriately");
        Invest2_sBTCContract.LetsInvestin_sBTC.value(sBTCPortion)(_toWhomToIssue);
        Invest2_sETHContract.LetsInvestin_sETH.value(sETHPortion)(_toWhomToIssue);
    }


    // this function should be called should we ever want to change the underlying Invest2_sETHContract address
    function set_Invest2_sETHContract (Invest2_sETH _Invest2_sETHContract) onlyOwner public {
        Invest2_sETHContract = _Invest2_sETHContract;
    }
    
    // this function should be called should we ever want to change the underlying Invest2_sBTCContract address
    function set_Invest2_sBTCContract (Invest2_sBTC _Invest2_sBTCContract) onlyOwner public {
        Invest2_sBTCContract = _Invest2_sBTCContract;
    }
    

    function inCaseTokengetsStuck(IERC20 _TokenAddress) onlyOwner public {
        uint qty = _TokenAddress.balanceOf(address(this));
        _TokenAddress.transfer(owner, qty);
    }
    
    // - fallback function let you / anyone send ETH to this wallet without the need to call any function
    function() external payable {
        if (msg.sender != owner) {
            LetsInvest(msg.sender, 50, 5);}
    }
    
    // - to Pause the contract
    function toggleContractActive() onlyOwner public {
        stopped = !stopped;
    }

    // - to withdraw any ETH balance sitting in the contract
    function withdraw() onlyOwner public{
        owner.transfer(address(this).balance);
    }
    
    // - to kill the contract
    function destruct() public onlyOwner {
        selfdestruct(owner);
    }


    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    
}