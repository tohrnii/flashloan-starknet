# Not safe to use in prod
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.uint256 import (Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_mul, uint256_unsigned_div_rem)
from interfaces.IERC20 import IERC20
from interfaces.IFlashLoanLender import IFlashLoanLender
from contracts.utils.constants import (TRUE, FALSE)

@storage_var
func reward_token() -> (token: felt):
end

@storage_var
func deposit_token() -> (token: felt):
end

const MIN_DEPOSIT = 100
const FLASH_MINING_AMOUNT = 10

@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        deposit_token_address: felt
    ):
    deposit_token.write(deposit_token_address)
    return ()
end

@external
func set_reward_token{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        reward_token_address: felt
    ):
    reward_token.write(reward_token_address)
    return ()
end

@external
func flash_mine{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        amount: Uint256
    ):
    alloc_locals
    let (local deposit_token_address: felt) = deposit_token.read()
    let (local reward_token_address: felt) = reward_token.read()
    let (local caller: felt) = get_caller_address()
    let (local this_contract: felt) = get_contract_address()
    let (local enough_deposit: felt) = uint256_le(Uint256(MIN_DEPOSIT, 0), amount)
    if enough_deposit != 0:
        IERC20.transferFrom(contract_address=deposit_token_address, sender=caller, recipient=this_contract, amount=amount)
        IERC20.transfer(contract_address=reward_token_address, recipient=caller, amount=Uint256(FLASH_MINING_AMOUNT, 0))
        IERC20.transfer(contract_address=deposit_token_address, recipient=caller, amount=amount)
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    return ()
end
