module mymod::main {
  use sui::transfer;
  use sui::object::{Self, UID, ID};
  use sui::tx_context::{Self, TxContext};
  use std::string::{Self, String, utf8};
  use sui::event;
  use sui::package;
  use sui::display;

  //===========================================================================
  // Structs
  //===========================================================================

  // Owner Capability Object
  struct OwnerCap has key {
    id: UID
  }

  // Can be transferable without the module
  struct Bird has key, store {
    id: UID,
    name: vector<u8>,
  }

  // Only transferable within the module
  struct SpecialBird has key {
    id: UID,
    name: vector<u8>,
  }

  struct Birdies has key {
    id: UID,
    count: u64,
  }

  // OTW
  struct MAIN has drop {}

  //===========================================================================
  // Events
  //===========================================================================

  struct TransferBird has copy, drop {
      from: address,
      to: address,
      bird: ID,
  }

  //===========================================================================
  // Methods
  //===========================================================================

  // Constructor
  fun init(otw: MAIN, ctx: &mut TxContext) {
      let publisher = package::claim(otw, ctx);

      let keys = vector[
            utf8(b"name"),
            utf8(b"age"),
            utf8(b"color"),
      ];

      let values = vector[
            utf8(b"{name}"),
            utf8(b"{age}"),
            utf8(b"{color}"),
      ];

      let display = display::new_with_fields<Birdies>(
            &publisher, keys, values, ctx
      );

      display::update_version(&mut display);

      transfer::public_transfer(publisher, tx_context::sender(ctx));
      transfer::public_transfer(display, tx_context::sender(ctx));
      transfer::transfer(OwnerCap {
          id: object::new(ctx),
      }, tx_context::sender(ctx));

      transfer::share_object(Birdies {
          id: object::new(ctx),
          count: 0,
      });
  }

  // Creates a OwnerCap object which can be called by every module / user
  public fun create(_: &OwnerCap, ctx: &mut TxContext): OwnerCap {
      OwnerCap { id: object::new(ctx) }
  }

  // Transfers the OwnerCap object to the given address, only callable by users, not by modules
  entry fun create_and_transfer(cap: &OwnerCap, to: address, ctx: &mut TxContext) {
      let cap = create(cap, ctx);
      transfer::transfer(cap, to);
  }

  // String module and string functions
  entry fun mint_bird(name: String, birdies: &mut Birdies, ctx: &mut TxContext) {
      let birb = Bird {
          id: object::new(ctx),
          name: *string::bytes(&name),
      };
      transfer::public_transfer(birb, tx_context::sender(ctx));

      birdies.count = 1 + birdies.count;
  }

  entry fun mint_special_bird(name: String, birdies: &mut Birdies, ctx: &mut TxContext) {
      let birb = SpecialBird {
          id: object::new(ctx),
          name: *string::bytes(&name),
      };
      transfer::transfer(birb, tx_context::sender(ctx));

      birdies.count = 1 + birdies.count;
  }

  entry fun transfer_special_bird(bird: SpecialBird, to: address, ctx: &mut TxContext) {
      // Emit event
      event::emit(TransferBird {
          from: tx_context::sender(ctx),
          to: to,
          bird: object::uid_to_inner(&bird.id),
      });

      transfer::transfer(bird, to);
  }
}