module sui_bank::bank {
  use sui::sui::SUI;
  use sui::transfer;
  use sui::coin::{Self, Coin};
  use sui::object::{Self, UID};
  use sui::balance::{Self, Balance};
  use sui::tx_context::{Self, TxContext};

  use sui_bank::sui_dollar::{Self, CapWrapper, SUI_DOLLAR};  

  struct Bank has key {
    id: UID,
    balance: Balance<SUI>,
    admin_balance: Balance<SUI>,
  }

  struct Account has key, store {
    id: UID,
    user: address,
    debt: u64,
    deposit: u64
  }

  struct OwnerCap has key, store {
    id: UID
  }

  const ENotEnoughBalance: u64 = 0;
  const EBorrowAmountIsTooHigh: u64 = 1;
  const EAccountMustBeEmpty: u64 = 2;
  const EPayYourLoan: u64 = 3;

  const FEE: u128 = 5;
  const EXCHANGE_RATE: u128 = 40;

  fun init(ctx: &mut TxContext) {
    transfer::share_object(
      Bank {
        id: object::new(ctx),
        balance: balance::zero(),
        admin_balance: balance::zero()
      }
    );

    transfer::transfer(OwnerCap { id: object::new(ctx) }, tx_context::sender(ctx));
  }

  // === Public Read Functions ===    

  public fun new_account(ctx: &mut TxContext): Account {
    Account {
      id: object::new(ctx),
      user: tx_context::sender(ctx),
      debt: 0,
      deposit: 0
    }
  }

  public fun balance(self: &Bank): u64 {
    balance::value(&self.balance)
  }

  public fun admin_balance(self: &Bank): u64 {
    balance::value(&self.admin_balance)
  }

  public fun user(account: &Account): address {
    account.user
  }

  public fun debt(account: &Account): u64 {
    account.debt
  } 

  public fun account_deposit(account: &Account): u64 {
    account.deposit
  }    

  // === Public Mut Functions ===    

  public fun deposit(self: &mut Bank, account: &mut Account, token: Coin<SUI>, ctx: &mut TxContext) {
    let value = coin::value(&token);
    let deposit_value = value - (((value as u128) * FEE / 100) as u64);
    let admin_fee = value - deposit_value;

    let admin_coin = coin::split(&mut token, admin_fee, ctx);
    balance::join(&mut self.admin_balance, coin::into_balance(admin_coin));
    balance::join(&mut self.balance, coin::into_balance(token));

    account.deposit = account.deposit + deposit_value;
  }  

  public fun withdraw(self: &mut Bank, account: &mut Account, value: u64, ctx: &mut TxContext): Coin<SUI> {
    assert!(account.debt == 0, EPayYourLoan);
    assert!(account.deposit >= value, ENotEnoughBalance);

    account.deposit = account.deposit - value;

    coin::from_balance(balance::split(&mut self.balance, value), ctx)
  }

  public fun borrow(account: &mut Account, cap: &mut CapWrapper, value: u64, ctx: &mut TxContext): Coin<SUI_DOLLAR> {
    let max_borrow_amount = (((account.deposit as u128) * EXCHANGE_RATE / 100) as u64);

    assert!(max_borrow_amount >= account.debt + value, EBorrowAmountIsTooHigh);

    account.debt = account.debt + value;

    sui_dollar::mint(cap, value, ctx)
  }

  public fun repay(account: &mut Account, cap: &mut CapWrapper, coin_in: Coin<SUI_DOLLAR>) {
    let amount = sui_dollar::burn(cap, coin_in);

    account.debt = account.debt - amount;
  }  
  
  public fun destroy_empty_account(account: Account) {
    let Account { id, debt: _, deposit, user: _ } = account;
    assert!(deposit == 0, EAccountMustBeEmpty);
    object::delete(id);
  }

  public fun swap_sui(cap: &mut CapWrapper, self: &mut Bank, coin_in: Coin<SUI>, ctx: &mut TxContext): Coin<SUI_DOLLAR> {
      let amount = exchange_rate_sui(&coin_in);
      balance::join(&mut self.balance, coin::into_balance(coin_in));
      sui_dollar::mint(cap, amount, ctx)
  }

  public fun swap_sui_dollar(cap: &mut CapWrapper, self: &mut Bank, coin_in: Coin<SUI_DOLLAR>, ctx: &mut TxContext): Coin<SUI> {
      let amount = exchange_rate_sui_dollar(sui_dollar::burn(cap, coin_in));
      coin::take(&mut self.balance, amount, ctx)
  }

  fun exchange_rate_sui(coin_in: &Coin<SUI>): u64 {
    (((coin::value(coin_in) as u128) * EXCHANGE_RATE / 100) as u64)
  }

  fun exchange_rate_sui_dollar(coin_in: u64): u64 {
    (((coin_in as u128) * 100 / EXCHANGE_RATE) as u64)
  }

  // === Admin Functions ===

  public fun claim(_: &OwnerCap, self: &mut Bank, ctx: &mut TxContext): Coin<SUI> {
    let value = balance::value(&self.admin_balance);
    coin::take(&mut self.admin_balance, value, ctx)
  }
}