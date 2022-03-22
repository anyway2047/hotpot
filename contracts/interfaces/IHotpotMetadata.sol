// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the hotpot project metadata
 */
interface IHotpotMetadata {
    /**
     * @dev Sets the values for {daoUrl}.
     */
    function setMetadata(string memory daoUrl) external returns (bool);

    /**
     * @dev Returns the logo of the dao project.
     */
    function daoUrl() external view returns (string memory);

}
