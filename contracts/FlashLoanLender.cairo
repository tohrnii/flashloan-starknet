# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_mul, uint256_unsigned_div_rem)
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import assert_not_zero, assert_lt
from contracts.utils.constants import (TRUE, FALSE)
from interfaces.IERC20 import IERC20
from interfaces.IFlashLoanBorrower import IFlashLoanBorrower

@storage_var
func user_balance(user: felt, token: felt) -> (amount: Uint256):
end

@storage_var
func fee() -> (res: felt):
end

const FEE_BASE = 1000000

@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        fee_ppm: felt
    ):
    fee.write(fee_ppm)
    return ()
end

@external
func deposit{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token: felt,
        amount: Uint256
    ):
    let (caller) = get_caller_address()
    let (this_contract) = get_contract_address()
    let (depositor_balance) = user_balance.read(caller, token)
    IERC20.transferFrom(contract_address=token, sender=caller, recipient=this_contract, amount=amount)
    let (new_depositor_balance, _: Uint256) = uint256_add(depositor_balance, amount)
    user_balance.write(caller, token, new_depositor_balance)
    return ()
end

@external
func withdraw{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token: felt,
        amount: Uint256
    ):
    alloc_locals
    let (caller) = get_caller_address()
    let (this_contract) = get_contract_address()
    let (local depositor_balance: Uint256) = user_balance.read(caller, token)
    let (enough_balance) = uint256_le(amount, depositor_balance)
    assert_not_zero(enough_balance)
    let (new_depositor_balance: Uint256) = uint256_sub(depositor_balance, amount)
    user_balance.write(caller, token, new_depositor_balance)
    IERC20.transfer(contract_address=token, recipient=caller, amount=amount)
    return ()
end

@external
func flash_loan{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        flash_loan_receiver: felt,
        token: felt,
        amount: Uint256,
        data: felt
    ) -> (bool: felt):
    alloc_locals
    let (local caller) = get_caller_address()
    let (local this_contract) = get_contract_address()
    let (local _fee_ppm) = fee.read()
    let (local _fee_ppm_amount, _: Uint256) = uint256_mul(Uint256(_fee_ppm, 0), amount)
    let (local _fee, _: Uint256) = uint256_unsigned_div_rem(_fee_ppm_amount, Uint256(FEE_BASE, 0))
    IERC20.transfer(contract_address=token, recipient=flash_loan_receiver, amount=amount)
    IFlashLoanBorrower.on_flash_loan(contract_address=flash_loan_receiver, initiator=caller, token=token, amount=amount, fee=_fee, data=data)
    let (local _repayment_amount, _: Uint256) = uint256_add(amount, _fee)
    IERC20.transferFrom(contract_address=token, sender=caller, recipient=this_contract, amount=_repayment_amount)
    return (TRUE)
end

@view
func flash_fee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token: felt, amount: Uint256
    ) -> (res: Uint256):
    alloc_locals
    let (local _fee_ppm) = fee.read()
    let (local _fee_ppm_amount, _: Uint256) = uint256_mul(Uint256(_fee_ppm, 0), amount)
    let (local _fee, _: Uint256) = uint256_unsigned_div_rem(_fee_ppm_amount, Uint256(FEE_BASE, 0))
    # let (local _fee, _: Uint256) = uint256_unsigned_div_rem(uint256_mul(fee.read(), amount), Uint256(FEE_BASE, 0))
    return (_fee)
end

@view
func max_flash_loan{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        token: felt
    ) -> (res: Uint256):
    let (this_contract) = get_contract_address()
    let (_balance) = IERC20.balanceOf(contract_address=token, account=this_contract)
    return (_balance)
end
