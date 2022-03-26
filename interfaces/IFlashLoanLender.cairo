%lang starknet

from starkware.cairo.common.uint256 import Uint256
from interfaces.IFlashLoanBorrower import IFlashLoanBorrower

@contract_interface
namespace IFlashLoanLender:

    func max_flash_loan(token: felt) -> (res: felt):
    end

    func flash_fee(token: felt, amount: Uint256) -> (res: Uint256):
    end

    func flash_loan(
            flash_loan_receiver: felt,
            token: felt,
            amount: Uint256,
            data: felt
        ) -> (bool: felt):
    end

end