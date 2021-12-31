// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ADTVesting is AccessControl {
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    IERC20 public token;
    uint public tge;

    uint private beneficiariesAmount;
    mapping(address => uint) private beneficiaries;
    mapping(address => uint) private tgeReleases;
    mapping(address => uint) private released;
    mapping(address => uint) private cliffDurations;
    mapping(address => uint) private durations;
    mapping(address => bool) private blockBeneficiaries;

    event Released(address beneficiary, uint amount);
    event Blocked(address beneficiary, string reason);
    event Unblocked(address beneficiary);

    constructor() {
        _setRoleAdmin(DEPLOYER_ROLE, DEPLOYER_ROLE);
        _setupRole(DEPLOYER_ROLE, msg.sender);
    }

    function setToken (address erc20) public onlyRole(DEPLOYER_ROLE) {
        require(address(token) == address(0), "The token is setted");
        token = IERC20(erc20);
    }

    function startTGE () public onlyRole(DEPLOYER_ROLE) {
        require(tge == 0, "TGE started before");
        tge = block.timestamp;
    }

    function addBeneficiary (address beneficiary, uint total, uint tgeRelease, uint cliffDuration, uint duration) public onlyRole(DEPLOYER_ROLE) {
        require(beneficiary != address(0) && beneficiaries[beneficiary] == 0, "The beneficiary is existed");
        require(token.balanceOf(address(this)) >= total + beneficiariesAmount, "The balance is not enough");
        require(tgeRelease <= total, "The TGE release is invalid");
        require(cliffDuration <= duration, "The cliff is longer than the duration");

        tgeReleases[beneficiary] = tgeRelease;
        cliffDurations[beneficiary] = cliffDuration;
        durations[beneficiary] = duration;
        blockBeneficiaries[beneficiary] = false;

        beneficiaries[beneficiary] = total;
        beneficiariesAmount += total;
    } 

    function getAllocation (address beneficiary) public view returns (uint) {
        require(beneficiaries[beneficiary] > 0, "The beneficiary address is invalid");
        return beneficiaries[beneficiary];
    }

    function getTGERelease(address beneficiary) public view returns (uint) {
        require(beneficiaries[beneficiary] > 0, "The beneficiary address is invalid");
        return tgeReleases[beneficiary];
    }

    function getReleased(address beneficiary) public view returns (uint) {
        require(beneficiaries[beneficiary] > 0, "The beneficiary address is invalid");
        return released[beneficiary];
    }

    function getCliffDuration(address beneficiary) public view returns (uint) {
        require(beneficiaries[beneficiary] > 0, "The beneficiary address is invalid");
        return cliffDurations[beneficiary];
    }

    function getCliff(address beneficiary) public view returns (uint) {
        require(beneficiaries[beneficiary] > 0, "The beneficiary address is invalid");
        require(tge > 0, "TGE is not config");
        return tge + cliffDurations[beneficiary];
    }

    function getDuration(address beneficiary) public view returns (uint) {
        require(beneficiaries[beneficiary] > 0, "The beneficiary address is invalid");
        return durations[beneficiary];
    }

    function blockBeneficiary (address beneficiary, string memory reason) public onlyRole(DEPLOYER_ROLE) {
        require(beneficiaries[beneficiary] > 0, "The beneficiary address is invalid");
        blockBeneficiaries[beneficiary] = true;
        emit Blocked(beneficiary, reason);
    } 

    function unBlockBeneficiary (address beneficiary) public onlyRole(DEPLOYER_ROLE) {
        require(beneficiaries[beneficiary] > 0, "The beneficiary address is invalid");
        blockBeneficiaries[beneficiary] = false;
        emit Unblocked(beneficiary);
    } 

    function release(address beneficiary) public {
        require(blockBeneficiaries[beneficiary] == false, "The beneficiary is not exists or blocked");
        uint vestableAmount = vestable(beneficiary);
        require(vestableAmount > 0, "The is nothing to vest");
        
        released[beneficiary] += vestableAmount;

        token.transfer(beneficiary, vestableAmount);
        emit Released(beneficiary, vestableAmount);
    }

    function vestable(address beneficiary) public view returns(uint) {
        require(beneficiaries[beneficiary] > 0, "The beneficiary address is invalid");
        require(tge > 0, "TGE is not config");
        uint amount = 0;

        if (block.timestamp > tge) {
            amount = tgeReleases[beneficiary];
        }

        if (block.timestamp < tge + cliffDurations[beneficiary]) {
            return amount - released[beneficiary];
        } else if (block.timestamp >= (tge + durations[beneficiary])) {
            return beneficiaries[beneficiary] - released[beneficiary];
        } else {
            return (beneficiaries[beneficiary] * (block.timestamp - tge) / durations[beneficiary]) - released[beneficiary];
        }
    }
}