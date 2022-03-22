// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IBondingCurve.sol";
import "./libraries/SafeMath.sol";


contract BondingSwap is IBondingCurve {

    using SafeMath for uint256;
    
    function fx(uint256 x) public pure returns(uint256) {
        return x.safeMul(x).safeMul(10).safeDiv(100).safeAdd(x.safeMul(10).safeDiv(1000)).safeDiv(10 ** 18);
    }
    
    function gasMint(uint256 x, uint256 y, uint256 fee) public override pure returns(uint256 gas) {
        return y.safeDiv(100);
    }
    
    function gasBurn(uint256 x, uint256 y, uint256 fee) public override pure returns(uint256 gas) {
        return y.safeDiv(100);
    }
    
    function mining(uint256 tokens, uint256 totalSupply) public override pure returns(uint256 x, uint256 y) {
        x = tokens;
        uint fx1 = fx(tokens.safeAdd(totalSupply));
        uint fx0 = fx(totalSupply);
        y = fx1.safeSub(fx0);
        return (x,y);
    }
    
    function burning(uint256 tokens, uint256 totalSupply) public override pure returns(uint256 x, uint256 y) {
        x = tokens;
        uint fx1 = fx(totalSupply);
        uint fx0 = fx(totalSupply.safeSub(tokens));
        y = fx1.safeSub(fx0);
        return (x,y);
    }

}
