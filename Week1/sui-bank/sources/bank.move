module bank::bank {
  use sui::sui::SUI;
  use sui::transfer;
  use sui::coin::{Self, Coin};
  use sui::object::{Self, UID};
  use sui::dynamic_field;
  use sui::balance::{Self, Balance};
  use sui::tx_context::{Self, TxContext};

    struct Bank has key {
        id: UID
    }

    struct OwnerCap has key, store {
        id: UID
    }

    struct UserBalance has copy, drop, store { user: address }
    struct AdminBalance has copy, drop, store {}

    const FEE: u128 = 5;

    const ENotEnoughBalance: u64 = 0;

    fun init(ctx: &mut TxContext) {
        let bank = Bank { id: object::new(ctx) };

        dynamic_field::add(&mut bank.id, AdminBalance {}, balance::zero<SUI>());

        transfer::share_object(
            bank
        );

        transfer::transfer(OwnerCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

      public fun withdraw(self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
        let sender = tx_context::sender(ctx);

        if (dynamic_field::exists_(&self.id, UserBalance { user: sender })) {
            coin::from_balance(dynamic_field::remove(&mut self.id, UserBalance { user: sender }), ctx)
        } else {
            coin::zero(ctx)
        }
    }

    public fun partial_withdraw(self: &mut Bank, value: u64, ctx: &mut TxContext): Coin<SUI> {
        let balance_mut = dynamic_field::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: tx_context::sender(ctx) });

        assert!(balance::value(balance_mut) >= value, ENotEnoughBalance);

        coin::take(balance_mut, value, ctx)
    }

    public fun deposit(self: &mut Bank, token: Coin<SUI>, ctx: &mut TxContext) {
        let value = coin::value(&token);
        let deposit_value = value - (((value as u128) * FEE / 100) as u64);
        let admin_fee = value - deposit_value;

        let admin_coin = coin::split(&mut token, admin_fee, ctx);
        balance::join(dynamic_field::borrow_mut<AdminBalance, Balance<SUI>>(&mut self.id, AdminBalance {}), coin::into_balance(admin_coin));

        if (dynamic_field::exists_(&self.id, UserBalance { user: tx_context::sender(ctx) })) {
            balance::join(dynamic_field::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: tx_context::sender(ctx) }),
            coin::into_balance(token));
        } else {
            dynamic_field::add(&mut self.id, UserBalance { user: tx_context::sender(ctx) }, coin::into_balance(token));
        };
    }

    public fun user_balance(self: &Bank, user: address): u64 {
        let key = UserBalance { user };
        if (dynamic_field::exists_(&self.id, key)) {
            balance::value(dynamic_field::borrow<UserBalance, Balance<SUI>>(&self.id, key))
        } else {
            0
        }
    }

    public fun admin_balance(self: &Bank): u64 {
        balance::value(dynamic_field::borrow<AdminBalance, Balance<SUI>>(&self.id, AdminBalance {}))
    }  

    public fun claim(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
        let fee_balance = balance::withdraw_all(
            dynamic_field::borrow_mut<AdminBalance, Balance<SUI>>(
                &mut self.id,
                AdminBalance { },
            ));
        coin::from_balance(fee_balance, ctx)
    }

    public fun balance(self: &mut Bank, user: address): u64 {
        if (dynamic_field::exists_(&self.id, UserBalance { user: user })) {
            balance::value(dynamic_field::borrow_mut<UserBalance, Balance<SUI>>(&mut self.id, UserBalance { user: user }))
        } else {
            0
        }
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}