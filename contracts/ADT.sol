// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";


contract DotArcadeToken is AccessControl, ERC20, ERC20Snapshot, ERC20Pausable {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    uint public maxTransferAmount;
    bool public isCheckMaxTransferAmount;

    uint public maxBalanceAmount;
    bool public isCheckMaxBalanceAmount;

    mapping(address=> uint) public whitelistTransferBots;
    mapping(address=> uint) public whitelistBalanceBots;

    constructor() ERC20("Dot Arcade", "ADT") {
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setupRole(OWNER_ROLE, msg.sender);

        // Strategic Sale | Wait for Vesting Contract Address
        //_mint(address(0), 12000000 * (10 ** decimals()));

        // Private Sale | Wait for Vesting Contract Address
        //_mint(address(0), 17000000 * (10 ** decimals()));

        // Public Sale
        _mint(0xEdE6B0fb9F5Aa27FED9bea25AFdCE1D492116371, 4000000 * (10 ** decimals()));

        // Team & Advisors | Wait for Vesting Contract Address
        //_mint(address(0), 60000000 * (10 ** decimals()));

        // Liquidity | Wait for Vesting Contract Address
        //_mint(address(0), 15000000 * (10 ** decimals()));

        // Marketing & Partnership | Wait for Vesting Contract Address
        //_mint(address(0), 30000000 * (10 ** decimals()));

        // Ingame Reward | Wait for Vesting Contract Address
        //_mint(address(0), 96000000 * (10 ** decimals()));

        // Ecosystem Funds | Wait for Vesting Contract Address
        //_mint(address(0), 66000000 * (10 ** decimals()));
    }

    /**
     * Utilities functions
     */
    function snapshot() public onlyRole(OWNER_ROLE) returns (uint) {
        return _snapshot();
    }

    function pause() public  onlyRole(OWNER_ROLE)  {
        _pause();
    }

    function unpause() public onlyRole(OWNER_ROLE)  {
        _unpause();
    }

    /**
     * Bot prevent functions
     */
    function toggleCheckMaxTransferAmount () public onlyRole(OWNER_ROLE) {
        isCheckMaxTransferAmount = !isCheckMaxTransferAmount;
    }

    function setMaxTransferAmount (uint amount) public onlyRole(OWNER_ROLE) {
        maxTransferAmount = amount;
    }

    function updateMaxTransferBots (address[] calldata bots, uint[] calldata amounts) public onlyRole(OWNER_ROLE) {
        for(uint i; i < bots.length; i++) {
            whitelistTransferBots[bots[i]] = amounts[i];
        }
    }

    function updateMaxBalanceBots (address[] calldata bots, uint[] calldata amounts) public onlyRole(OWNER_ROLE) {
        for(uint i; i < bots.length; i++) {
            whitelistBalanceBots[bots[i]] = amounts[i];
        }
    }

    function toggleCheckMaxBalanceAmount () public onlyRole(OWNER_ROLE) {
        isCheckMaxBalanceAmount = !isCheckMaxBalanceAmount;
    }

    function setMaxBalanceAmount (uint amount) public onlyRole(OWNER_ROLE) {
        maxBalanceAmount = amount;
    }

    function _checkForMaxTransfer(address from, uint amount) internal view {
        if(isCheckMaxTransferAmount){
            require(amount <= maxTransferAmount || amount <= whitelistTransferBots[from], 
                "ADT: Prevent Bot");
        }
    }

    function _checkForMaxBalance(address to, uint256 amount) internal view {
        if(isCheckMaxBalanceAmount){
            require(balanceOf(to) + amount <= maxBalanceAmount || 
                    balanceOf(to) + amount <= whitelistBalanceBots[to],
                    "ADT: Prevent Bot");
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override(ERC20, ERC20Pausable, ERC20Snapshot) {
        _checkForMaxTransfer(from, amount);
        _checkForMaxBalance(to, amount);

        super._beforeTokenTransfer(from, to, amount);
    }
}