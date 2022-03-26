import os

import pytest
from starkware.starknet.testing.starknet import Starknet
from utils import Signer, uint, str_to_felt

# The path to the contract source code.
FLASH_LOAN_LENDER_FILE = os.path.join("contracts", "FlashLoanLender.cairo")
FLASH_LOAN_BORROWER_FILE = os.path.join("contracts", "FlashLoanBorrower.cairo")
ACCOUNT_FILE = os.path.join("contracts", "lib", "Account.cairo")
ERC20_FILE = os.path.join("contracts", "mock", "ERC20.cairo")

user = Signer(123456789)

@pytest.mark.asyncio
async def test_flash_loan():

    starknet = await Starknet.empty()

    user_account = await starknet.deploy(
        ACCOUNT_FILE,
        constructor_calldata=[user.public_key]
    )
    
    flash_loan_lender = await starknet.deploy(
        source=FLASH_LOAN_LENDER_FILE,
        constructor_calldata=[1000]
    )

    flash_loan_borrower = await starknet.deploy(
        source=FLASH_LOAN_BORROWER_FILE,
        constructor_calldata=[flash_loan_lender.contract_address]
    )
    
    mock_erc20 = await starknet.deploy(
        source=ERC20_FILE,
        constructor_calldata=[
            str_to_felt('ERC20'),
            str_to_felt('ERC20'),
            18,
            *uint(100000),
            user_account.contract_address
        ]
    )

    #Transfer tokens to flash borrower
    await user.send_transaction(
        user_account,
        mock_erc20.contract_address,
        'transfer',
        [
            flash_loan_borrower.contract_address,
            *uint(10000)
        ]
    )

    #Approve tokens for flash lender
    await user.send_transaction(
        user_account,
        mock_erc20.contract_address,
        'approve',
        [
            flash_loan_lender.contract_address,
            *uint(10000)
        ]
    )

    #Deposit tokens in flash lender
    await user.send_transaction(
        user_account,
        flash_loan_lender.contract_address,
        'deposit',
        [
            mock_erc20.contract_address,
            *uint(10000)
        ]
    )
    
    #Flash Borrow
    await user.send_transaction(
        user_account,
        flash_loan_borrower.contract_address,
        'flash_borrow',
        [
            mock_erc20.contract_address,
            *uint(10000),
            0
        ]
    )

    #Flash Borrower ERC20 balance
    flash_borrower_erc20_balance = (await mock_erc20.balanceOf(flash_loan_borrower.contract_address).call()).result.balance
    assert flash_borrower_erc20_balance[0] == 9990

    #Flash Lender ERC20 balance
    flash_lender_erc20_balance = (await mock_erc20.balanceOf(flash_loan_lender.contract_address).call()).result.balance
    assert flash_lender_erc20_balance[0] == 10010
    