module sui_bank::oracle {
  // === Imports ===

  use sui::clock:: {Clock, timestamp_ms};

  use sui::math as sui_math;

  use switchboard::aggregator::{Self, Aggregator};
  use switchboard::math;

  // === Constants ===

  const MINIMUM_VALID_TIMESTAMP: u64 = 520000;

  // === Errors ===

  const EPriceIsNegative: u64 = 0;
  const EValueIsNegative: u64 = 1;
  const EInvalidTimestamp: u64 = 2;
  const EFeedNotWhitelisted:u64 = 3;

  // === Structs ===

  struct Price {
    latest_result: u128,
    scaling_factor: u128,
    latest_timestamp: u64,
  }

  struct AggregatorTable has key {
    id: UID,
    whitelist: vector<address>,
  }

  // === Init ===

  fun init(ctx: &mut TxContext) {
    transfer::share_object(
      AggregatorTable{
        id: object::new(ctx),
        whitelist: vector::empty(),
      },
    );
  }

  // === Public-Mutative Functions ===

  public fun new(feed: &Aggregator, aggregator_table: &mut AggregatorTable, clock: &Clock): Price {
    assert!(vector::contains(&aggregator.whitelist, &aggregator::aggregator_address(feed)), EFeedNotWhitelisted);

    let (latest_result, latest_timestamp) = aggregator::latest_value(feed);

    assert!((timestamp_ms(clock) - (latest_timestamp * 1000)) <= MINIMUM_VALID_TIMESTAMP, EInvalidTimeStamp);

    let (value, scaling_factor, neg) = math::unpack(latest_result);

    assert!(value > 0, EValueIsNegative);
    assert!(!neg, EPriceIsNegative);

    Price {
      latest_result: value,
      scaling_factor: (sui_math::pow(10, scaling_factor) as u128),
      latest_timestamp
    }
  }

  public fun destroy(self: Price): (u128, u128, u64) {
    let Price { latest_result, scaling_factor, latest_timestamp } = self;
    (latest_result, scaling_factor, latest_timestamp)
  }

  public fun add_aggregator(aggregator_table: &mut AggregatorTable, aggregator: &Aggregator) {
    vector::push_back(&mut aggregator_table.whitelist, aggregator::aggregator_address(aggregator));
  }

  // === Test Functions ===

  #[test_only]
  
  public fun new_for_testing(latest_result: u128, scaling_factor: u128, latest_timestamp: u64): Price {
    Price {
      latest_result,
      scaling_factor,
      latest_timestamp
    }
  }
}