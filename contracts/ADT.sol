// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";

contract DotArcadeToken is AccessControl, ERC20, ERC20Snapshot, ERC20Pausable {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    bool public isInProventBotMode;

    mapping(address=> bool) private whitelistAddresses;
    mapping(address=> bool) private blacklistAddresses;

    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // Mainnet
    // address constant BUSD = 0x85A0B362648a04B0ed33Ed5DeCd4b506D673c44b; // Testnet

    IUniswapV2Router02 constant public uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
    //IUniswapV2Router02 constant public uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Testnet

    address public pairADTBUSD;

    uint public listingTime;

    constructor() ERC20("Dot Arcade", "ADT") {
        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());
        pairADTBUSD = uniswapV2Factory.createPair(address(this), BUSD);

        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setupRole(OWNER_ROLE, msg.sender);

        // Strategic Sale
        _mint(0x6792056B7B6743d3670D9c3F26c80499CBB2F090, 12000000 * (10 ** decimals()));

        // Private Sale
        _mint(0x6d92A8Add425199d90641d1BC3d942031B752Ea4, 17000000 * (10 ** decimals()));

        // Public Sale
        _mint(0xEdE6B0fb9F5Aa27FED9bea25AFdCE1D492116371, 4000000 * (10 ** decimals()));

        // Team & Advisors
        _mint(0xf91664CF02B9d5c518656F3666aa93178ecF6C07, 60000000 * (10 ** decimals()));

        // Liquidity Fund
        _mint(0x93fA2807C23723D3eC78C9e15d99F694516A2528, 15000000 * (10 ** decimals()));

        // Marketing & Partnership
        _mint(0xf812bE41C852cD6cbf33EcBB2A0E1FC23e04eC5E, 30000000 * (10 ** decimals()));

        // Ingame Reward
        _mint(0x5a2Cb51E0627a4eAB0ae95c7B6C44f8097636A21, 96000000 * (10 ** decimals()));

        // Ecosystem Funds
        _mint(0xa732c8d0922107B01f963cf8E8522fEaEe695DF6, 66000000 * (10 ** decimals()));


        // // For testing purpose
        // _mint(msg.sender, 10000000 * (10 ** decimals()));
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

    //Use this function to confirm listingTime
    function addFirstLiquidity (uint amountADTDesired, uint amountBUSDDesired) public onlyRole(OWNER_ROLE) {
        require(listingTime == 0, "ADT: LP added before");
        require(this.transferFrom(msg.sender, address(this), amountADTDesired), "ADT: Cannot transfer ADT");
        require(IERC20(BUSD).transferFrom(msg.sender, address(this), amountBUSDDesired), "ADT: Cannot transfer BUSD");

        //Approve for router
        require(this.approve(address(uniswapV2Router), amountADTDesired), "ADT: Cannot approve ADT");
        require(IERC20(BUSD).approve(address(uniswapV2Router), amountBUSDDesired), "ADT: Cannot approve BUSD");

        listingTime = block.timestamp;

        uniswapV2Router.addLiquidity(address(this), BUSD, amountADTDesired, amountBUSDDesired, 0, 0, msg.sender, block.timestamp);
    }

    /**
     * Bot prevent functions
     */
    function addBackList (address[] calldata _list) public onlyRole(OWNER_ROLE) {
        for(uint i=0; i < _list.length; i++) {
            blacklistAddresses[_list[i]] = true;
        }
    }

    function addWhiteList (address[] calldata _list) public onlyRole(OWNER_ROLE) {
        for(uint i=0; i < _list.length; i++) {
            whitelistAddresses[_list[i]] = true;
        }
    }

    function togglePreventBotMode () public onlyRole(OWNER_ROLE) {
        isInProventBotMode = !isInProventBotMode;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override(ERC20, ERC20Pausable, ERC20Snapshot) {
        if (isInProventBotMode) {
            if (listingTime > 0 ) {
                // 1. Chặn mua bán 4 block đầu sau khi listing
                if (block.timestamp - listingTime <= 12) {
                    revert("ADT::PreventBot: Buy/Sell block");
                }
                
                if (block.timestamp - listingTime <= 180) {
                    // 5. Chặn bán đối với các backlist user
                    if (blacklistAddresses[from] == true) {
                        revert("ADT::PreventBot: Blacklist");
                    } 

                    // 4. Chỉ cho user trong whitelist mua trong 3' đầu
                    if (whitelistAddresses[to] != true) {
                        revert("ADT::PreventBot: Whitelist only");
                    }
                }
            }
        }

        super._beforeTokenTransfer(from, to, amount);
    }
}
