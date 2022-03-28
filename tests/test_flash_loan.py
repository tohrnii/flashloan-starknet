import os

import pytest
from starkware.starknet.testing.starknet import Starknet
from utils import Signer, uint, str_to_felt

# The path to the contract source code.
FLASH_LOAN_LENDER_FILE = os.path.join("contracts", "FlashLoanLender.cairo")
FLASH_LOAN_BORROWER_FILE = os.path.join("contracts", "FlashLoanBorrower.cairo")
ACCOUNT_FILE = os.path.join("contracts", "lib", "Account.cairo")
ERC20_FILE = os.path.join("contracts", "mock", "ERC20.cairo")
FLASH_MINING_FILE = os.path.join("contracts", "mock", "FlashMining.cairo")
FLASH_MINING_BORROWER_FILE = os.path.join("contracts", "mock", "FlashMiningBorrower.cairo")

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
    

@pytest.mark.asyncio
async def test_flash_mining():

    starknet = await Starknet.empty()

    user_account = await starknet.deploy(
        ACCOUNT_FILE,
        constructor_calldata=[user.public_key]
    )
    
    flash_loan_lender = await starknet.deploy(
        source=FLASH_LOAN_LENDER_FILE,
        constructor_calldata=[1000]
    )
    
    flash_mining_borrower = await starknet.deploy(
        source=FLASH_MINING_BORROWER_FILE,
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

    flash_mining = await starknet.deploy(
        source=FLASH_MINING_FILE,
        constructor_calldata=[mock_erc20.contract_address]
    )

    reward_erc20 = await starknet.deploy(
        source=ERC20_FILE,
        constructor_calldata=[
            str_to_felt('MINE'),
            str_to_felt('MINE'),
            18,
            *uint(100000),
            flash_mining.contract_address
        ]
    )

    # set flash mining contract
    await user.send_transaction(
        user_account,
        flash_mining_borrower.contract_address,
        'set_mining_contract',
        [
            flash_mining.contract_address
        ]
    )

    # set reward token
    await user.send_transaction(
        user_account,
        flash_mining.contract_address,
        'set_reward_token',
        [
            reward_erc20.contract_address
        ]
    )

    #Transfer tokens to flash mining borrower
    await user.send_transaction(
        user_account,
        mock_erc20.contract_address,
        'transfer',
        [
            flash_mining_borrower.contract_address,
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
    
    #Flash Mining Borrow
    await user.send_transaction(
        user_account,
        flash_mining_borrower.contract_address,
        'flash_borrow',
        [
            mock_erc20.contract_address,
            *uint(10000),
            1
        ]
    )

    #Flash Mining Borrower Mock ERC20 balance
    flash_mining_borrower_erc20_balance = (await mock_erc20.balanceOf(flash_mining_borrower.contract_address).call()).result.balance
    assert flash_mining_borrower_erc20_balance[0] == 9990

    #Flash Lender Mock ERC20 balance
    flash_lender_erc20_balance = (await mock_erc20.balanceOf(flash_loan_lender.contract_address).call()).result.balance
    assert flash_lender_erc20_balance[0] == 10010
    
    #Flash Mining Borrower reward token balance
    flash_mining_borrower_reward_token_balance = (await reward_erc20.balanceOf(flash_mining_borrower.contract_address).call()).result.balance
    assert flash_mining_borrower_reward_token_balance[0] == 10