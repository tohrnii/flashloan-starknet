# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.uint256 import (Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_mul, uint256_unsigned_div_rem)
from interfaces.IERC20 import IERC20
from interfaces.IFlashLoanLender import IFlashLoanLender
from contracts.utils.constants import (TRUE, FALSE)

@storage_var
func flash_loan_lender_address() -> (res: felt):
end

@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        flash_loan_lender: felt
    ):
    flash_loan_lender_address.write(flash_loan_lender)
    return ()
end

@external
func on_flash_loan{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        initiator: felt,
        token: felt,
        amount: Uint256,
        fee: Uint256,
        data: felt
    ) -> (bool: felt):
    let (caller) = get_caller_address()
    let (flash_lender) = flash_loan_lender_address.read()
    let (this_contract) = get_contract_address()
    assert caller = flash_lender
    assert initiator = this_contract

    #############################################
    #
    #
    # Do your thing here
    #
    #
    #############################################

    return (TRUE)
end

@external
func flash_borrow{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        token: felt,
        amount: Uint256,
        data: felt
    ) -> (bool: felt):
    let (this_contract) = get_contract_address()
    let (flash_lender) = flash_loan_lender_address.read()
    let (_fee: Uint256) = IFlashLoanLender.flash_fee(contract_address=flash_lender, token=token, amount=amount)
    let (_repayment, _: Uint256) = uint256_add(amount, _fee)
    IERC20.approve(contract_address=token, spender=flash_lender, amount=_repayment)
    let (_bool) = IFlashLoanLender.flash_loan(contract_address=flash_lender, flash_loan_receiver=this_contract, token=token, amount=amount, data=data)
    return (bool = _bool)
end