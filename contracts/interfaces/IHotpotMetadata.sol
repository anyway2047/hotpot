// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the hotpot project metadata
 */
interface IHotpotMetadata {
    /**
     * @dev Sets the values for {daoName} and {daoUrl} and {introduction}.
     */
    function setMetadata(string memory daoName,
                            string memory daoUrl,
                            string memory introduction) external returns (bool);

    /**
     * @dev Returns the dao name of the dao project.
     */
    function daoName() external view returns (string memory);

    /**
     * @dev Returns the logo of the dao project.
     */
    function daoUrl() external view returns (string memory);

    /**
     * @dev Returns the introduction of the  dao project.
     */
    function introduction() external view returns (string memory);

}
