// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }

}

interface IBondingCurve {
    // Processing logic must implemented in subclasses

    function gasMint(uint256 x, uint256 y, uint256 gasFee) external pure returns(uint256 gas);

    function mining(uint256 tokens, uint256 totalSupply) external pure  returns(uint256 x, uint256 y);

    function gasBurn(uint256 x, uint256 y, uint256 gasFee) external pure returns(uint256 gas);

    function burning(uint256 tokens, uint256 totalSupply) external pure  returns(uint256 x, uint256 y);

}

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
