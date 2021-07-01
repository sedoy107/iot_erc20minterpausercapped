// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/../../access/AccessControlEnumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauserCapped is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CAPCHG_ROLE = keccak256("CAPCHG_ROLE");

    /**
     * @dev _cap is not immutable compared to the openzeppilin's original
     * declaration in {ERC20Capped-constructor}
     */
    uint256 private _cap;

    /**
     * @dev Emitted when token's cap is modified.
     */
    event CapChanged(uint256 prev_cap, uint256 new_cap);

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     * Sets the value of the `cap`. Sets up a new role to allow modifying `cap`.
     */
    constructor(string memory name, string memory symbol, uint256 cap_) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(CAPCHG_ROLE, _msgSender());
        
        _setCap(cap_);
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev Modified the current cap of the token's total supply
     * MUST check the role to allow modification of cap
     * 
     * Emits a {CapChanged} event with previous and new `cap` values .
     * 
     * Requirements:
     * - sender's `account` must have role `CAPCHG_ROLE`
     * - Proposed `new_cap' value MUST be greater than the `ERC20.totalSupply()`.
     */
    function setCap(uint256 new_cap) public returns (bool) {
        require(hasRole(CAPCHG_ROLE, _msgSender()), "Must have cap changer role");
        require(new_cap > ERC20.totalSupply(), "Total supply exceeds the proposed cap");
        uint256 prev_cap = _cap;
        _setCap(new_cap);
        emit CapChanged(prev_cap, new_cap);
        return true;
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

    function _setCap(uint256 cap_) private {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }
}
