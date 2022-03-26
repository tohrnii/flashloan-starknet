%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IFlashLoanBorrower:
    func on_flash_loan(
        initiator: felt,
        token: felt,
        amount: Uint256,
        fee: Uint256,
        data: felt
    ) -> (bool: felt):
    end
end