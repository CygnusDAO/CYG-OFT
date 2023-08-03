// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import {OFTV2} from "./OFTV2.sol";

/**
 *  @title CygnusDAO CYG token built as layer-zero`s OFTV2.
 *  @notice On each chain the CYG token is deployed there is a cap of 2.5M to be minted over 42 epochs (4 years).
 *          See https://github.com/CygnusDAO/cygnus-token/blob/main/contracts/cygnus-token/PillarsOfCreation.sol
 *          Instead of using `totalSupply` to cap the mints, we must keep track internally of the total minted
 *          amount, to not break compatability with the OFTV2's `_debitFrom` and `_creditTo` functions (since these
 *          burn and mint supply into existence respectively).
 */
contract CygnusDAO is OFTV2 {
    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            1. ERRORS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @custom:error ExceedsSupplyCap Reverts when minting above cap
    error ExceedsSupplyCap();

    /// @custom:error PillarsAlreadySet Reverts when assigning the minter contract again
    error PillarsAlreadySet();

    /// @custom:error OnlyPillars Reverts when msg.sender is not the CYG minter contract
    error OnlyPillars();

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            2. STORAGE
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @notice Maximum cap of CYG on this chain
    uint256 public constant CAP = 2_500_000e18;

    /// @notice The CYG minter contract
    address public pillarsOfCreation;

    /// @notice Stored minted amount
    uint256 public totalMinted;

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            3. CONSTRUCTOR
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    ///  @notice Constructs the CYG OFTV2 token and gives sender initial ownership to set paths.
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _sharedDecimals,
        address _lzEndpoint
    ) OFTV2(_name, _symbol, _sharedDecimals, _lzEndpoint) {
        uint256 initial = 250_000e18;
        totalMinted += initial;
        _mint(msg.sender, initial);
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            4. MODIFIERS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /// @notice Modifier for minting only if msg.sender is CYG minter contract
    modifier onlyPillars() {
        _checkPillars();
        _;
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            5. CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ─────────────────────────────────────────────── Private ───────────────────────────────────────────────  */

    /// @notice Reverts if msg.sender is not CYG minter
    function _checkPillars() private view {
        /// @custom:error OnlyPillars
        if (msg.sender != pillarsOfCreation) revert OnlyPillars();
    }

    /*  ═══════════════════════════════════════════════════════════════════════════════════════════════════════ 
            6. NON-CONSTANT FUNCTIONS
        ═══════════════════════════════════════════════════════════════════════════════════════════════════════  */

    /*  ────────────────────────────────────────────── External ───────────────────────────────────────────────  */

    /// @notice Assigns the only contract on the chain that can mint the CYG token. Can only be set once.
    /// @param _pillars The address of the minter contract
    /// @custom:security onlyOwner
    function setPillarsOfCreation(address _pillars) external onlyOwner {
        /// @custom:error PillarsAlreadySet Avoid setting the CYG minter after it has been initialized
        if (_pillars != address(0)) revert PillarsAlreadySet();

        // Assign the only contract that can mint CYG tokens
        pillarsOfCreation = _pillars;
    }

    /// @notice Mints CYG token into existence.
    /// @param to The receiver of the CYG token
    /// @param amount The amount of CYG token to mint
    /// @custom:security onlyPillars
    function mint(address to, uint256 amount) external onlyPillars {
        /// @custom:error ExceedsSupplyCap Avoid minting above cap
        if (totalMinted + amount > CAP) revert ExceedsSupplyCap();

        // Increase minted amount
        totalMinted += amount;

        // Mint internally
        _mint(to, amount);
    }
}
