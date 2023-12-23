// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/******************************************************************************\
* Original Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Jesper Kristensen: modified to be simpler for demonstration purposes.
*
* Honour: further modified for more simplicity
/******************************************************************************/

library LibDiamond {
  /// Storage slots of this diamond
  // load the storage of the diamond contract at a specific location:
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  event DiamondCut(FacetCut _diamondCut);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  struct FacetCut {
    address facetAddress; // address of the contract representing the facet of the diamond
    bytes4[] functionSelectors; // which functions from this new facet do we want registered
  }

  // Access existing facets and functions (aka selectors):
  struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  /** ==================================================================
                            General Diamond Storage Space
    =====================================================================*/

  /**
   * @notice Core diamond storage space
   */
  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    //Array of all the selectors
    bytes4[] selectors;
    // owner of the diamond contract
    address contractOwner;
  }

  // access core storage via:
  function diamondStorage() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  /** ==================================================================
                        CUT NEW FACETS INTO THIS DIAMOND
    =====================================================================*/

  // The main function that is used to cut new facets into the diamond (aka add a new contract and its functions to the diamond)
  // Internal function version of diamondCut
  function diamondCut(FacetCut calldata _diamondCut, address _init, bytes calldata _calldata) internal {
    address facetAddress = _diamondCut.facetAddress;
    bytes4[] memory functionSelectors = _diamondCut.functionSelectors;

    require(functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    require(facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");

    DiamondStorage storage ds = diamondStorage(); // store in "core" storage

    uint16 selectorPosition = uint16(ds.selectors.length); //0 - 65535(2^16) should be more than sufficient

    // add each new incoming function selector to this facet
    for (uint256 selectorIndex; selectorIndex < functionSelectors.length; selectorIndex++) {
      bytes4 selector = functionSelectors[selectorIndex];

      // ensure the facet does not already exist:
      address currentFacetAddressIfAny = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(currentFacetAddressIfAny == address(0), "LibDiamondCut: Can't add function that already exists");

      // ADD The function (selector) here:
      // map the selector to the position in the overall selector array and also map it to the facet address
      ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
      ds.selectorToFacetAndPosition[selector].facetAddress = facetAddress;
      // we track the selectors in an array under the facet address
      ds.selectors.push(selector);

      selectorPosition++;
    }
    initializeFacet(_init, _calldata);
    emit DiamondCut(_diamondCut);
  }

  function initializeFacet(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      return;
    }
    _enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
    (bool success, bytes memory error) = _init.delegatecall(_calldata);
    if (!success) {
      if (error.length > 0) {
        // bubble up error
        /// @solidity memory-safe-assembly
        assembly {
          let returndata_size := mload(error)
          revert(add(32, error), returndata_size)
        }
      } else {
        revert("initialization function reverted");
      }
    }
  }

  /** ==================================================================
                            Core Diamond State
    =====================================================================*/

  // core diamond contract ownership:
  function setContractOwner(address _newOwner) internal {
    DiamondStorage storage ds = diamondStorage();
    address previousOwner = ds.contractOwner;
    ds.contractOwner = _newOwner;
    emit OwnershipTransferred(previousOwner, _newOwner);
  }

  function contractOwner() internal view returns (address) {
    return diamondStorage().contractOwner;
  }

  function enforceIsContractOwner() internal view {
    require(_msgSender() == contractOwner(), "LibDiamond: Must be contract owner");
  }

  // private functions in this section

  function _enforceHasContractCode(address _contract, string memory _errorMessage) private view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize > 0, _errorMessage);
  }

  function _msgSender() private view returns (address) {
    // put msg.sender behind a private view wall
    return msg.sender;
  }
}
