# Project Dogfish

A Frictionless, Decentralized, Deregulated, Double-Blind Lending Contract

## Summary

Conventional loans and BitBond loans are bound by myriad bookkeeping, regulation,
taxation, and transaction limitations which reduce the efficiency of lending
markets and deprive unconventional borrowers and entrepreneurs of funding options.
Ethereum smart contracts present an opportunity to resolve all of these problems.

## Implementation

A smart contract auction occurs to crowdfund a loan. Each proposed bid contains
a profit, and the borrower may accept or ignore incoming bids. If enough bids
are accepted to meet the total by the auction deadline, then the loan amount is
awarded to the borrower and an ERC20-compliant token is minted for the loan.

Ignored bids can be refunded in full, while lenders receive a share of the token
commensurate with their stake
`[ (bid_amount + bid_profit) / sum(bid_amounts + bid_profits) ]`. They can either
trade their shares on token exchanges or cash their shares out
`[ (shares / totalSupply) / paidBack ]`, destroying their shares and increasing
the relative reward for the remaining shareholders.

By design, this contract doesn't define the temporal terms of the loan. It also
does not integrate conventional interest or penalties. Though it doesn't
preclude them, either. They merely need to be tracked elsewhere, off of the chain,
along with the rest of the loan origination documentation.

## Considerations

Unlike BitBond, which features a limited and inflexible collections process of
politely delivering robo-calls to deadbeat borrowers/scammers, shares of Dogfish
loans which have been defaulted on can be sold to collections specialists. This
creates an efficient aftermarket and allows for a more efficient separation of
investor specializations; originators, value investors, and collection
specialists, ...each one empowered to invest in their preferred stage in the
loan’s life-cycle.
