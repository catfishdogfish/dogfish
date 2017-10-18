pragma solidity ^0.4.13;

contract Dogfish {

	address public borrower;

	string public constant name = "Dogfish Loan";
	string public constant symbol = "DFL";
	uint8  public constant decimals = 18;

	uint256 public totalRaised   = 0.0; // can't exceed 'amount'
	uint256 public totalPayback  = 0.0; // amount plus profits
	uint256 public totalPaidback = 0.0; // amount paid back by borrower
	uint256 public totalSupply   = 0.0; // Starts as payback, shrinks after cash-out

	mapping(address => uint256) balances;

	// Owner of account approves the transfer of an amount to another account
	mapping(address => mapping (address => uint256)) allowed;

	uint256 public amount;
	uint256 public auction_final;
	bool    public awarded = false;

	struct Bid {
		address bidder;
		uint256 bid_amount;
		uint256 bid_profit;
		bool    accepted;
		bool    released;
	}

	mapping(uint256 => Bid) public bids;
	uint256 bid_incr = 0;

	function Dogfish( uint256 _amount, uint256 _auction_final ) {
		require( _amount        > 0.0 );
		require( _auction_final > block.timestamp );

		borrower = msg.sender;

		amount        = _amount;
		auction_final = _auction_final;
	}

	event Bidded( uint256 bid_id, uint256 bid_amount, uint256 bid_profit );
	function bid( uint256 bid_amount, uint256 bid_profit ) {
		require( bid_amount    >= amount / 100.0 );
		require( auction_final  > block.timestamp );

		bids[++bid_incr] = Bid({
			bidder:     msg.sender,
			bid_amount: msg.value,
			bid_profit: bid_profit,
			accepted:   false,
			released:   false
		});

		Bidded( bid_incr, bid_amount, bid_profit );
	}

	event Bid_Approved( uint bid_id, bool loan_awarded );
	function bid_approve( uint bid_id ) {
		require( !bids[bid_id].accepted );
		require( msg.sender    == borrower );
		require( auction_final >= block.timestamp );
		require( totalRaised    < amount ); // can't approve more than amount

		if(totalRaised + bids[bid_id].bid_amount < amount ) {

			totalRaised  += bids[bid_id].bid_amount;
			totalPayback += bids[bid_id].bid_amount + bids[bid_id].bid_profit;

			bids[bid_id].accepted = true;

		} else { // conditional to deal with the bid that crosses the finish line

			uint256 surplus = (totalRaised + bids[bid_id].bid_amount) - amount;
			totalRaised = amount;

			totalPayback +=
				( bids[bid_id].bid_amount + bids[bid_id].bid_profit )
				*
				( ( bids[bid_id].bid_amount - surplus) / bids[bid_id].bid_amount );

			if( surplus > 0.0 ) {
				// refund without a request in case of split bid
				bids[bid_id].bidder.transfer( surplus );


				bids[bid_id].bid_profit =
					bids[bid_id].bid_profit
					*
					( ( bids[bid_id].bid_amount - surplus ) / bids[bid_id].bid_amount );


				bids[bid_id].bid_amount -= surplus;
			}

			// bid isn't flagged as released, despite partial refund
			bids[bid_id].accepted = true;

			totalSupply = totalPayback;

			borrower.transfer( amount );
			awarded = true; // award loan if an approved bid crosses the finish line
		}

		bids[bid_id].accepted = true;

		Bid_Approved( bid_id, awarded );
	}

	function bid_refund( uint256 bid_id ) {
		require( auction_final < block.timestamp || awarded );
		require( bids[bid_id].bid_amount > 0.0 );
		require( !bids[bid_id].accepted );
		require( !bids[bid_id].released );
		require( bids[bid_id].bidder == msg.sender );

		bids[bid_id].released = true;
		msg.sender.transfer( bids[bid_id].bid_amount );
	}

	function mint( uint256 bid_id ) {
		require( awarded );
		require( bids[bid_id].accepted );
		require( !bids[bid_id].released );
		require( bids[bid_id].bid_amount > 0.0 );
		require( bids[bid_id].bidder == msg.sender );

		balances[msg.sender] += bids[bid_id].bid_amount + bids[bid_id].bid_profit;

		bids[bid_id].released = true;

	}

	// pay out current return relative to share of investment and shrink shareholder pool
	function cash( uint256 cash_amount ) {
		require( awarded );
		require( totalPaidback > 0.0 );
		require( balances[msg.sender] >= cash_amount );

		uint256 payout =
			cash_amount
			*
			( totalPaidback / totalSupply );

		msg.sender.transfer( payout );

		totalSupply -= cash_amount;
		balances[msg.sender] -= cash_amount;
	}

	function () payable {
		totalPaidback += msg.value;
	}

	function totalSupply() constant returns (uint256 totalSupply) {
		return totalSupply;
	}

	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	// Transfer the balance from owner's account to another account
	function transfer(address _to, uint256 _amount) returns (bool success) {
		if (balances[msg.sender] >= _amount 
				&& _amount > 0
				&& balances[_to] + _amount > balances[_to]) {
			balances[msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(msg.sender, _to, _amount);
			return true;
		} else {
			return false;
		}
	}

	function transferFrom(
			address _from,
			address _to,
			uint256 _amount
			) returns (bool success) {
		if (balances[_from] >= _amount
				&& allowed[_from][msg.sender] >= _amount
				&& _amount > 0
				&& balances[_to] + _amount > balances[_to]) {
			balances[_from] -= _amount;
			allowed[_from][msg.sender] -= _amount;
			balances[_to] += _amount;
			Transfer(_from, _to, _amount);
			return true;
		} else {
			return false;
		}
	}

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	// Allow _spender to withdraw from your account, multiple times, up to the _value amount.
	// If this function is called again it overwrites the current allowance with _value.
	function approve(address _spender, uint256 _amount) returns (bool success) {
		allowed[msg.sender][_spender] = _amount;
		Approval(msg.sender, _spender, _amount);
		return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}
}
