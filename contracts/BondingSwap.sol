// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IBondingCurve.sol";
import "./libraries/SafeMath.sol";


contract BondingSwap is IBondingCurve {

    using SafeMath for uint256;

    function fx(uint256 x) public pure returns(uint) {
        uint256 swap = x.safeMul(x).safeDiv(2);
        return swap;
    }

    function gasMint(uint256 x, uint256 y, uint256 gasFee) public override pure returns(uint256 gas) {
        return y.safeMul(gasFee).safeDiv(10000);
    }

    function gasBurn(uint256 x, uint256 y, uint256 gasFee) public override pure returns(uint256 gas) {
        return y.safeMul(gasFee).safeDiv(10000);
    }

    function mining(uint256 tokens, uint256 totalSupply) public override pure returns(uint256 x, uint256 y) {
        x = tokens;
        uint256 fx1 = fx(tokens.safeAdd(totalSupply));
        uint256 fx0 = fx(totalSupply);
        y = fx1.safeSub(fx0);
        return (x, y);
    }

    function burning(uint256 tokens, uint256 totalSupply) public override pure returns(uint256 x, uint256 y) {
        x = tokens;
        uint256 fx1 = fx(totalSupply);
        uint256 fx0 = fx(totalSupply.safeSub(tokens));
        y = fx1.safeSub(fx0);
        return (x, y);
    }

}
