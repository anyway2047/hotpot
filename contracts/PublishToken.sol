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

interface IHotpot {

    function setTreasury(address account) external returns (bool);

    function initialSupply() external view returns (uint256);

    function balanceOfLockedPresale(address account) external view returns (uint256);

    function balanceOfPresale(address account) external view returns (uint256);

    function releasePresale() external returns (bool);

    function transferPresale(address recipient, uint256 amount, uint256 lockTime, uint256 releaseTime) external returns (bool);

    function presaleStrategy() external view returns (uint256 amount, uint256 lockTime, uint256 releaseTime, uint256 startTime, uint256 unit);

    function setTreasuryFee( uint256 fee) external returns (bool);

    event TransferPresale(address indexed from, address indexed to, uint256 value);

}

interface IHotpotERC20 {

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IHotpotMetadata {

    function setMetadata(string memory daoName,
        string memory daoUrl,
        string memory introduction) external returns (bool);

    function daoName() external view returns (string memory);

    function daoUrl() external view returns (string memory);

    function introduction() external view returns (string memory);

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract MintLicensable {

    IBondingCurve coinMaker;

    event CoinMakerChanged(address indexed _from, address indexed _to);

    function _changeCoinMaker(address newBonding) internal {
        coinMaker = IBondingCurve(newBonding);
        emit CoinMakerChanged(address(coinMaker), newBonding);
    }

    function _mining(uint256 tokens, uint256 totalSupply) internal view returns(uint256 x, uint256 y) {
        return coinMaker.mining(tokens, totalSupply);
    }

    function _burning(uint256 tokens, uint256 totalSupply) internal view returns(uint256 x, uint256 y) {
        return coinMaker.burning(tokens, totalSupply);
    }

    function _gasFeeMint(uint256 x, uint256 y, uint256 fee) internal view returns(uint256 gas) {
        return coinMaker.gasMint(x, y, fee);
    }

    function _gasFeeBurn(uint256 x, uint256 y, uint256 fee) internal view returns(uint256 gas) {
        return coinMaker.gasBurn(x, y, fee);
    }

    function getBondingCurve() public view returns(address) {
        return address(coinMaker);
    }

}

contract Hotpot is IHotpot, IHotpotERC20, IHotpotMetadata, MintLicensable, Ownable {

    using SafeMath for uint256;

    struct PresaleLockStrategy {

        uint256 lockTime;

        uint256 releaseTime;

        uint256 startTime;

        uint256 releaseUnit;

    }

    struct HotpotMetadata {

        string  _daoName;

        string  _daoUrl;

        string  _introduction;
    }

    HotpotMetadata private _metadata;

    mapping(address => uint256) private _balances;

    mapping(address => uint256) private _lockedPresale;

    mapping(address => uint256) private _releasedPresale;

    mapping(address => PresaleLockStrategy) private _presaleLockStrategy;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 private _initialSupply;

    address public _treasury;
    uint256 private _treasuryFee;
    uint256 private _projectFee = 100;
    address private _project = 0x5d37D54390aE20A250f7C7c8276147BfFaa5ab09;

    string private _name;
    string private _symbol;

    uint256 public oneDay = 24 * 60 * 60;

    constructor(string memory name_, string memory symbol_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _initialSupply = initialSupply_;
        _releasedPresale[msg.sender] = initialSupply_;
        _treasury = msg.sender;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply * 10 ** 18;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[from] = fromBalance - amount;
    }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
        _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function setMetadata(string memory daoName,
        string memory daoUrl,
        string memory introduction) external virtual override onlyOwner returns (bool) {
        _metadata._daoName = daoName;
        _metadata._daoUrl = daoUrl;
        _metadata._introduction = introduction;
        return true;
    }

    function daoName() public view virtual override returns (string memory){
        return _metadata._daoName;
    }

    function daoUrl() public view virtual override returns (string memory){
        return _metadata._daoUrl;
    }

    function introduction() public view virtual override returns (string memory){
        return _metadata._introduction;
    }

    function setTreasury(address account) external virtual override onlyOwner returns (bool){
        _treasury = account;
        return true;
    }

    function initialSupply() external view virtual override returns (uint256){
        return _initialSupply;
    }

    function balanceOfLockedPresale(address account) external view virtual override returns (uint256){
        return  _lockedPresale[account];
    }

    function balanceOfPresale(address account) external view virtual override returns (uint256){
        return  _releasedPresale[account];
    }

    function releasePresale() external virtual override returns (bool){
        address account = msg.sender;

        uint256 lockTime = _presaleLockStrategy[msg.sender].lockTime;
        uint256 startTime = _presaleLockStrategy[msg.sender].startTime;
        uint256 releaseUnit = _presaleLockStrategy[msg.sender].releaseUnit;

        require(startTime != 0, "releasePresale: Strategy does not exist");

        uint256 nowTime = block.timestamp;
        uint256 subTime = nowTime - startTime;
        uint256 subDays = subTime / oneDay;
        require(subDays >= lockTime, "releasePresale: The pledge time is not met");

        uint256 releaseDays = (subDays - lockTime) + 1;
        uint256 releaseTotal = releaseDays * releaseUnit;
        uint256 released = _releasedPresale[account];

        require(releaseTotal > released, "releasePresale: You have nothing to release");

        uint256 releaseAmount = releaseTotal - released;
        _releasedPresale[account] = releaseTotal;
        _balances[account] += releaseAmount;

        return true;
    }

    function transferPresale(address recipient, uint256 amount, uint256 lockDays, uint256 releaseTime) external virtual override onlyOwner returns (bool){

        uint256 fromBalance = _releasedPresale[msg.sender];
        require(fromBalance >= amount, "Presale: transfer amount exceeds balance");
        require(_lockedPresale[recipient] == 0, "Presale: transfer amount exceeds balance");
    unchecked {
        _releasedPresale[msg.sender] = fromBalance - amount;
    }
        _lockedPresale[recipient] += amount;

        uint256 startTime = block.timestamp;

        uint256 releaseUnit = amount / releaseTime;

        _presaleLockStrategy[recipient] = PresaleLockStrategy(lockDays, releaseTime, startTime, releaseUnit);

        return true;
    }

    function presaleStrategy() external view virtual override returns (uint256 amount, uint256 lockTime, uint256 releaseTime, uint256 startTime, uint256 unit){
        address account = msg.sender;

        amount = _lockedPresale[account];
        lockTime = _presaleLockStrategy[account].lockTime;
        releaseTime = _presaleLockStrategy[account].releaseTime;
        startTime = _presaleLockStrategy[account].startTime;
        unit = _presaleLockStrategy[account].releaseUnit;

        return(amount, lockTime, releaseTime, startTime, unit);
    }

    function setTreasuryFee(uint256 fee) external virtual override onlyOwner returns (bool){
        _treasuryFee = fee;
        return true;
    }

    function transferAnyERC20Token(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        return IHotpotERC20(tokenAddress).transfer(tokenAddress, tokens);
    }

    function setBondingCurve(address newBonding) public onlyOwner {
        _changeCoinMaker(newBonding);
    }

    function mint(uint256 tokens) public payable {
        // Calculate the actual amount through Bonding Curve
        address to = msg.sender;
        uint256 x;
        uint256 y;
        (x, y)= _mining(tokens, _totalSupply);
        uint256 fee = _gasFeeMint(x, y, _treasuryFee);
        uint256 _projectFee = y.safeMul(_projectFee).safeDiv(10000);

        y = y.safeAdd(fee).safeAdd(_projectFee);
        require(x > 0);
        require(y >= 0);
        uint256 need = y.safeAdd(fee).safeAdd(_projectFee);
        require(need <= msg.value);

        payable(_treasury).transfer(fee);
        payable(_project).transfer(_projectFee);
        // The extra value is transferred to the sender itself
        if(need < msg.value) {
            payable(msg.sender).transfer((msg.value).safeSub(need));
        }

        _balances[to] = (_balances[to]).safeAdd(x * (10 ** 18));
        _totalSupply = _totalSupply.safeAdd(x);
        emit Mined(to, x);
    }

    function testMint(uint256 tokens) public view returns (uint256 x, uint256 y, uint256 fee) {
        (x, y) = _mining(tokens, _totalSupply);
        fee = _gasFeeMint(x, y, _treasuryFee);
        fee = fee.safeAdd((y.safeMul(_projectFee).safeDiv(10000)));
        return (x, y, fee);
    }

    function burn(uint tokens) public payable {
        // Calculate the actual amount through Bonding Curve
        address from = msg.sender;
        uint256 x;
        uint256 y;
        (x, y) = _burning(tokens, _totalSupply);
        uint256 fee = _gasFeeBurn(x, y, _treasuryFee);
        uint256 _projectFee = y.safeMul(_projectFee).safeDiv(10000);

        require(x > 0);
        require(_balances[from] >= x);
        require(address(this).balance >= y);
        require(y >= fee);

        payable(_treasury).transfer(fee);
        payable(_project).transfer(_projectFee);
        payable(from).transfer(y.safeSub(fee).safeSub(_projectFee));

        _balances[from] = (_balances[from]).safeSub(x * (10 ** 18));
        _totalSupply = _totalSupply.safeSub(x);
        emit Burned(from, x);
    }

    function testBurn(uint256 tokens) public view returns (uint256 x, uint256 y, uint256 fee) {
        (x, y) = _burning(tokens, _totalSupply);
        fee = _gasFeeBurn(x, y, _treasuryFee);
        fee = fee.safeAdd((y.safeMul(_projectFee).safeDiv(10000)));
        return (x, y, fee);
    }

    function assets() public view returns (uint256) {
        return address(this).balance;
    }

    event Mined(address indexed _to, uint256 tokens);

    event Burned(address indexed _from, uint256 tokens);

}

