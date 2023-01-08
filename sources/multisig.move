module multisig::token_vault {
    use std::vector;
    use sui::object::{Self, ID,UID};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};

    const INVALID_SIGNER: u64 = 0;
    const OWNER_MISMATCHED: u64 = 1;
    const AlreadySigned:u64 =2;
    const NotEnoughSigners:u64 =3;
    const COIN_MISMATCHED:u64 =4;
    const ALREADY_EXECUTED:u64 =5;

    struct Multisig has key,store {
        id:UID,
        owners: vector<address>,
        threshold: u64,
    }

    struct Transaction<phantom T> has key {
        id:UID,
        did_execute: bool,
        multisig: ID,
        sui: Balance<SUI>,
        token: Balance<T>,
        signers: vector<bool>,
        receiver: address,
    }
    public entry fun create_multisig(
        owners: vector<address>,
        threshold: u64,
        ctx: &mut TxContext
    ){
        let multisig_data = Multisig{
                    id: object::new(ctx),
                    owners,
                    threshold
        };
        transfer::transfer(multisig_data, tx_context::sender(ctx));
    }
    // to-do check multisig wallet or object id
    public entry fun create_transaction<T>(
        receiver: address,
        sui: Coin<SUI>,
        token: Coin<T>,
        multisig_data: &mut Multisig,
        ctx: &mut TxContext
    ){
        let owners_length = vector::length(&multisig_data.owners);
        let signers = vector::empty<bool>();
        let (is_owner,index) = vector::index_of(&multisig_data.owners,&tx_context::sender(ctx));
        assert!(is_owner==true,OWNER_MISMATCHED);
        let i = 0;
        while (i < owners_length) {
            if (i==index){
                vector::push_back(&mut signers, true);
            }
            else{
                vector::push_back(&mut signers, false);
            };
            i = i + 1;
        };
        let transaction_data = Transaction{
                    id: object::new(ctx),
                    did_execute: false,
                    multisig: *object::uid_as_inner(&multisig_data.id),
                    sui: coin::into_balance(sui),
                    token: coin::into_balance(token),
                    signers,
                    receiver
        };
        transfer::transfer(transaction_data, tx_context::sender(ctx));
    }
    public entry fun approve_transaction<T>(
        multisig_data: &mut Multisig,
        transaction_data: &mut Transaction<T>,
        ctx: &mut TxContext
    ){
        let owners = multisig_data.owners;
        let signers = transaction_data.signers;
        let (is_owner,index) = vector::index_of(&owners,&tx_context::sender(ctx));
        assert!(is_owner==true,OWNER_MISMATCHED);
        assert!(*vector::borrow(&signers,index)==false,AlreadySigned);
        let owners_length = vector::length(&multisig_data.owners);
        let i = 0;
        while (i < owners_length) {
            if (i==index){
                vector::push_back(&mut signers, true);
            };
            i = i + 1;
        };
    }
    public entry fun execute_transaction<T>(
         multisig_data: &mut Multisig,
        transaction_data: &mut Transaction<T>,
        sui: Coin<SUI>,
        ctx: &mut TxContext
    ){
        assert!(transaction_data.did_execute==false,ALREADY_EXECUTED);
        let owners = multisig_data.owners;
        let signers = transaction_data.signers;
        let (is_owner,_index) = vector::index_of(&owners,&tx_context::sender(ctx));
        assert!(is_owner==true,OWNER_MISMATCHED);
        let owners_length = vector::length(&multisig_data.owners);
        let i = 0;
        let total_signers = 0;
        while (i < owners_length) {
            let (havs_signed,_index) = vector::index_of(&signers,&true);
            if (havs_signed==true){
                total_signers=total_signers+1
            };
            i = i + 1;
        };
        if(total_signers >= multisig_data.threshold){
            // transfer sui
        };
    }
    fun send_balance(balance: Balance<SUI>, to: address, ctx: &mut TxContext) {
        transfer::transfer(coin::from_balance(balance, ctx), to)
    }
}