# FlashLoan Starknet

Sample implementation of flashloans in cairo where anyone can deposit any ERC20 token in a pool and flash borrowers can borrow as long as they return the borrowed amount + fee by the end of the transaction.

## Spec
Based on: https://eips.ethereum.org/EIPS/eip-3156

---

## Deploy

```
nile compile
nile deploy FlashLoanBorrower --alias <alias> --network <network>
nile deploy FlashLoanLender --alias <alias> --network <network>
```
---

## Test
```
pytest tests/test_flash_loan.py -s
```
---

## Deployment Addresses


## Credits

This repo is based on standard cairo contract library by [@OpenZeppelin](https://github.com/OpenZeppelin) : [Repo](https://github.com/OpenZeppelin/cairo-contracts)
