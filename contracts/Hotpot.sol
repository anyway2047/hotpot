// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./abstract/Ownable.sol";
import "./interfaces/IHotpot.sol";
import "./interfaces/IHotpotERC20.sol";
import "./interfaces/IHotpotMetadata.sol";
import "./structs/HotpotMetadata.sol";
import "./structs/PresaleLockStrategy.sol";
import "./abstract/MintLicensable.sol";
import "./libraries/SafeMath.sol";

/**
 * @dev Implementation of the {IHotpot} interface.
 */

contract Hotpot is IHotpot, IHotpotERC20, IHotpotMetadata, MintLicensable, Ownable {

    using SafeMath for uint256;

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
    /**
     * @dev Sets the values for {name} and {symbol} and {initialSupply}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint256 initialSupply_) {
        _name = name_;
        _symbol = symbol_;
        _initialSupply = initialSupply_;
        _releasedPresale[msg.sender] = initialSupply_;
        _treasury = msg.sender;
    }

    /// ---- Implementation of the IHotpotERC20 interface.  ---- ///

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IHotpotERC20-balanceOf} and {IHotpotERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IHotpotERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply * 10 ** 18;
    }

    /**
     * @dev See {IHotpotERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IHotpotERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IHotpotERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IHotpotERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IHotpotERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IHotpotERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IHotpotERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
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

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /// ---- Implementation of the IHotpotMetadata interface.  ---- ///

    /**
     * @dev Sets the values for {daoName} and {daoUrl} and {introduction}.
     */

    function setMetadata(string memory daoName,
        string memory daoUrl,
        string memory introduction) external virtual override onlyOwner returns (bool) {
        _metadata._daoName = daoName;
        _metadata._daoUrl = daoUrl;
        _metadata._introduction = introduction;
        return true;
    }

    /**
     * @dev Returns the dao name of the dao project.
     */
    function daoName() public view virtual override returns (string memory){
        return _metadata._daoName;
    }

    /**
     * @dev Returns the logo of the dao project.
     */
    function daoUrl() public view virtual override returns (string memory){
        return _metadata._daoUrl;
    }

    /**
     * @dev Returns the introduction of the  dao project.
     */
    function introduction() public view virtual override returns (string memory){
        return _metadata._introduction;
    }

    /// ---- Implementation of the IHotpot interface.  ---- ///

    function setTreasury(address account) external virtual override onlyOwner returns (bool){
        _treasury = account;
        return true;
    }

    /**
     * @dev Returns the amount of tokens presale.
     */
    function initialSupply() external view virtual override returns (uint256){
        return _initialSupply;
    }

    /**
     * @dev Returns the amount of the locked presale tokens owned by `account`.
     */
    function balanceOfLockedPresale(address account) external view virtual override returns (uint256){
        return  _lockedPresale[account];
    }

    /**
     * @dev Returns the amount of the released presale tokens owned by `account`.
     */
    function balanceOfPresale(address account) external view virtual override returns (uint256){
        return  _releasedPresale[account];
    }

    /**
     * @dev release the locked presale tokens by unique strategy
     */
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

    /**
     * @dev Moves presale `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
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

    /**
     * @dev presaleStrategy
     */
    function presaleStrategy() external view virtual override returns (uint256 amount, uint256 lockTime, uint256 releaseTime, uint256 startTime, uint256 unit){
        address account = msg.sender;

        amount = _lockedPresale[account];
        lockTime = _presaleLockStrategy[account].lockTime;
        releaseTime = _presaleLockStrategy[account].releaseTime;
        startTime = _presaleLockStrategy[account].startTime;
        unit = _presaleLockStrategy[account].releaseUnit;

        return(amount, lockTime, releaseTime, startTime, unit);
    }

    /**
     * @dev setTreasuryFee
     */
    function setTreasuryFee(uint256 fee) external virtual override onlyOwner returns (bool){
        _treasuryFee = fee;
        return true;
    }

    /// ---- Implementation of the BondingSwap interface.  ---- ///

    /**
     * @dev Owner can transfer out any accidentally sent ERC20 tokens
     */
    function transferAnyERC20Token(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        return IHotpotERC20(tokenAddress).transfer(tokenAddress, tokens);
    }

    /**
     * @dev Owner can transfer out any accidentally sent ERC20 tokens
     */

    function setBondingCurve(address newBonding) public onlyOwner {
        _changeCoinMaker(newBonding);
    }

    /**
     * @dev mint
     */

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

    /**
     * @dev testMint
     */

    function testMint(uint256 tokens) public view returns (uint256 x, uint256 y, uint256 fee) {
        (x, y) = _mining(tokens, _totalSupply);
        fee = _gasFeeMint(x, y, _treasuryFee);
        fee = fee.safeAdd((y.safeMul(_projectFee).safeDiv(10000)));
        return (x, y, fee);
    }

    /**
     * @dev burn
     */
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
