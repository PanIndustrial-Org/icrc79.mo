// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead

import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import D "mo:base/Debug";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import MapLib "mo:map/Map";
import SetLib "mo:map/Set";
import VecLib "mo:vector";
import BTreeLib "mo:stableheapbtreemap/BTree";
import BTree "mo:stableheapbtreemap/BTree";
import TTLib "mo:timer-tool";
import Service "../../Service";
import v0_1_0 "../v000_001_000/types";
/*

import Star "mo:star/star";
 */

module {

  let debug_channel = {
    subscribe = true;
  };

  private func logDebug(bEmit: Bool, message: Text) {
    if(bEmit) D.print(message);
  };

  public let Map = MapLib;
  public let Set = SetLib;
  public let Vector = VecLib;
  public let BTree = BTreeLib;
  public let TimerTool = TTLib;

  public type Account = v0_1_0.Account;

  public type Value = v0_1_0.Value;

  public let isICRC80 = v0_1_0.isICRC80;

  public type Interval =  v0_1_0.Interval;

  public type Asset = v0_1_0.Asset;
  public type AssetClass = v0_1_0.AssetClass;

  public type SubStatus = v0_1_0.SubStatus;

  public type TokenCanisterPointer = v0_1_0.TokenCanisterPointer;

  public type SubscriptionState = v0_1_0.SubscriptionState;

  public type CheckRate =  v0_1_0.CheckRate;

  public type SubscriptionStateShared = v0_1_0.SubscriptionStateShared;

  public let shareSubscriptionState = v0_1_0.shareSubscriptionState;

  public type ProductSubscriptionMap = v0_1_0.ProductSubscriptionMap; 
  public type ProductSubscriptionMap2 =  BTreeLib.BTree<?Nat, BTree.BTree<Nat, Bool>>;
  
  public type ServiceSubscriptionMap = v0_1_0.ServiceSubscriptionMap;
  public type ServiceSubscriptionMap2 = BTreeLib.BTree<Principal, ProductSubscriptionMap2>;

  public type SubAccountSubscriptionMap = v0_1_0.SubAccountSubscriptionMap;
  public type SubAccountSubscriptionMap2 = BTreeLib.BTree<Blob, ServiceSubscriptionMap2>;

  public type UserSubscriptionIndex = v0_1_0.UserSubscriptionIndex;
  public type UserSubscriptionIndex2 = BTreeLib.BTree<Principal, SubAccountSubscriptionMap2>;

  public type Subscription = {
      subscriptionId: Nat;
      tokenCanister: Principal;
      tokenPointer: ?Blob;
      serviceCanister: Principal;
      interval: Interval;
      productId: ?Nat;
      amountPerInterval: Nat;
      baseRateAsset: ?Asset;
      brokerId: ?Account;
      endDate: ?Nat; // Timestamp in nanoseconds to end the subscription
      targetAccount: ?Account;
      account: Account;
      status: SubStatus;
  };

  public func subAccountCompare(a : ?Blob, b : ?Blob) : Order.Order {
    switch(a, b){
      case(null, null) return #equal;
      case(?vala, ?valb){
       Blob.compare(vala, valb);
      };
      case(null,?val){
        Blob.compare(nullSubaccount, val);
      };
      case(?val,null){
        Blob.compare(val, nullSubaccount);
      };
    };
  };


  public func userSubscriptionCompare(a : Service.Subscription, b : Service.Subscription) : Order.Order {
    switch(Principal.compare(a.account.owner, b.account.owner)){
      case(#equal) {
         switch(subAccountCompare(a.account.subaccount, b.account.subaccount)){
          case(#equal) {
            switch(Principal.compare(a.serviceCanister, b.serviceCanister)){
              case(#equal) {
                switch(nullNcompare(a.productId, b.productId)){
                  case(#equal) {
                    Nat.compare(a.subscriptionId, b.subscriptionId);
                  };
                  case(#less) {
                    return #less;
                  };
                  case(#greater) {
                    return #greater;
                  };
                };
              };
              case(#less) {
                return #less;
              };
              case(#greater) {
                return #greater;
              };
            };
          };
          case(#less) {
            return #less;
          };
          case(#greater) {
            return #greater;
          };
         };
      };
      case(#less) {
        return #less;
      };
      case(#greater) {
        return #greater;
      };
    };
  };

  public func userPaymentRecordCompare(a : Service.PaymentRecord, b : Service.PaymentRecord) : Order.Order {
    switch(Principal.compare(a.account.owner, b.account.owner)){
      case(#equal) {
         switch(subAccountCompare(a.account.subaccount, b.account.subaccount)){
          case(#equal) {
            switch(Principal.compare(a.service, b.service)){
              case(#equal) {
                switch(nullNcompare(a.productId, b.productId)){
                  case(#equal) {
                    switch(Nat.compare(a.subscriptionId, b.subscriptionId)){
                      case(#equal) {
                        return Nat.compare(a.paymentId, b.paymentId);
                      };
                      case(#less) {
                        return #less;
                      };
                      case(#greater) {
                        return #greater;
                      };
                    };
                  };
                  case(#less) {
                    return #less;
                  };
                  case(#greater) {
                    return #greater;
                  };
                };
              };
              case(#less) {
                return #less;
              };
              case(#greater) {
                return #greater;
              };
            };
          };
          case(#less) {
            return #less;
          };
          case(#greater) {
            return #greater;
          };
         };
      };
      case(#less) {
        return #less;
      };
      case(#greater) {
        return #greater;
      };
    };
  };


  public type GlobalSubscriptionMap = v0_1_0.GlobalSubscriptionMap;
  public type GlobalSubscriptionMap2 =  BTree.BTree<Nat, SubscriptionState>;


  public type ScheduledPaymentArgs = v0_1_0.ScheduledPaymentArgs;


  ///MARK: Interceptors
  public type CanAddSubscription = v0_1_0.CanAddSubscription;


  public type TokenInfo = v0_1_0.TokenInfo;

  public type KnownTokenMap = v0_1_0.KnownTokenMap;

  public type KnownAssetMap = v0_1_0.KnownAssetMap;

  

  public type ServiceNotificationType = v0_1_0.ServiceNotificationType;

  
  public type ExchangeRate = v0_1_0.ExchangeRate;

  public type ExchangeRateError = v0_1_0.ExchangeRateError;
  public type ExchangeRateMetadata = v0_1_0.ExchangeRateMetadata;

  public type ServiceNotification = v0_1_0.ServiceNotification;

  

  

  /// `Stats`
  ///
  /// Represents collected statistics about the ledger, such as the total number of accounts.
  public type Stats = v0_1_0.Stats;

  public let subAccountEqual = v0_1_0.subAccountEqual;

  public let knownTokenHash32 = v0_1_0.knownTokenHash32;

  public let knownTokenEq = v0_1_0.knownTokenEq;

    public let knownTokenCompare = v0_1_0.knownTokenCompare;

  public let ktHash = (v0_1_0.knownTokenHash32, v0_1_0.knownTokenEq);

  public let assetHash32 = v0_1_0.assetHash32;

  public let assetEq = v0_1_0.assetEq;

    public let assetCompare = v0_1_0.assetCompare;

  public let assetHash = (v0_1_0.assetHash32, v0_1_0.assetEq);

  public let nullNHash32 = v0_1_0.nullNHash32;

  public let nullNeq = v0_1_0.nullNeq;

  public let nullNcompare = v0_1_0.nullNcompare;

  public let nullNHash = v0_1_0.nullNHash;
  public let accountHash32 = v0_1_0.accountHash32;

  public let nullSubaccount = v0_1_0.nullSubaccount;

  public let accountEq = v0_1_0.accountEq;

  public let accountCompare = v0_1_0.accountCompare;

  public let ahash = (v0_1_0.accountHash32, v0_1_0.accountEq);

  public type PaymentRecord = v0_1_0.PaymentRecord;

  public type PaymentRecord2 = {
    paymentId: Nat;
    date: Nat; // Timestamp of the payment
    amount: Nat;
    var fee: ?Nat;
    var brokerFee: ?Nat;
    var brokerTransactionId: ?Nat;
    rate: ?ExchangeRate; // if used
    var ledgerTransactionId: ?Nat;
    var transactionId: ?Nat;
    var feeTransactionId: ?Nat;
    subscriptionId: Nat;
    productId: ?Nat;
    service: Principal;
    targetAccount: ?Account;
    account: Account;
    result: {
      #Ok;
      #Err: {
        code: Nat;
        message: Text;
      };
    };
  };

  public func servicePaymentRecordCompare(a : Service.PaymentRecord, b : Service.PaymentRecord) : Order.Order {
    switch(Principal.compare(a.service, b.service)){
      case(#equal) {
        switch(nullNcompare(a.productId, b.productId)){
          case(#equal) {
      
            switch(Nat.compare(a.subscriptionId, b.subscriptionId)){
              case(#equal) {
                Nat.compare(a.paymentId, b.paymentId);
              };
              case(#less) {
                return #less;
              };
              case(#greater) {
                return #greater;
              };
            };
              
          };
          case(#less) {
            return #less;
          };
          case(#greater) {
            return #greater;
          };
        };
      };
      case(#less) {
        return #less;
      };
      case(#greater){
        return #greater;
      };
    };
  };

  public func serviceSubscriptionCompare(a : Service.Subscription, b : Service.Subscription) : Order.Order {
    switch(Principal.compare(a.serviceCanister, b.serviceCanister)){
      case(#equal) {
        switch(nullNcompare(a.productId, b.productId)){
          case(#equal) {
            Nat.compare(a.subscriptionId, b.subscriptionId);
          };
          case(#less) {
            return #less;
          };
          case(#greater) {
            return #greater;
          };
        };
      };
      case(#less) {
        return #less;
      };
      case(#greater){
        return #greater;
      };
    };
  };

  public func subaccountToBlob(aBlob : ?Blob) : Blob {
      switch(aBlob){
        case(null) nullSubaccount;
        case(?val) val;
      };
    };

  public func findOrCreateUserProductMap(state: State, subscription: SubscriptionState) : BTree.BTree<Nat, Bool> {

    debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap" # debug_show(subscription));
    
    let accountMap : SubAccountSubscriptionMap2 = switch(BTree.get(state.userSubscriptionIndex2, Principal.compare, subscription.account.owner)){
      case(null) {

        debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap accountMap null" # debug_show(subscription.account.owner));
        let accountMap = BTree.init<Blob, ServiceSubscriptionMap2>(null);
        ignore BTree.insert<Principal, SubAccountSubscriptionMap2>(state.userSubscriptionIndex2, Principal.compare, subscription.account.owner, accountMap);
        accountMap;
      };
      case(?val) val;
    };

    let subBlob = subaccountToBlob(subscription.account.subaccount);

    let serviceMap : ServiceSubscriptionMap2 = switch(BTree.get(accountMap, Blob.compare, subBlob)){
      case(null) {
        debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap serviceMap null" # debug_show(subscription.account.subaccount));
        let serviceMap = BTree.init<Principal, ProductSubscriptionMap2>(null);
        ignore BTree.insert<Blob, ServiceSubscriptionMap2>(accountMap, Blob.compare, subBlob, serviceMap);
        serviceMap;
      };
      case(?val) val;
    };

    let productSubMap = switch(BTree.get(serviceMap, Principal.compare, subscription.serviceCanister)){
      case(null) {
        debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap productMap null" # debug_show(subscription.serviceCanister));
        let productSubMap = BTree.init<?Nat, BTree.BTree<Nat, Bool>>(null);
        ignore BTree.insert(serviceMap, Principal.compare, subscription.serviceCanister, productSubMap);
        productSubMap;
      };
      case(?val) val;
    };

    let productMap = switch(BTree.get(productSubMap, nullNcompare, subscription.productId)){
      case(null) {
        debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap productMap null" # debug_show(subscription.productId));
        let productMap = BTree.init<Nat, Bool>(null);
        ignore BTree.insert(productSubMap, nullNcompare, subscription.productId, productMap);
        productMap;
      };
      case(?val) val;
    };

    productMap;
  };

  public func findOrCreateServiceProductMap(state: State, subscription: SubscriptionState) : BTree.BTree<Nat,Bool> {

    debug logDebug(debug_channel.subscribe, "Subs: findOrCreateServiceProductMap" # debug_show(subscription));
    let productSubMap = switch(BTree.get(state.serviceSubscriptionIndex2, Principal.compare, subscription.serviceCanister)){
      case(null) {
        debug logDebug(debug_channel.subscribe, "Subs: findOrCreateServiceProductMap productMap null" # debug_show(subscription.serviceCanister));
        let productSubMap = BTree.init<?Nat, BTree.BTree<Nat, Bool>>(null);
        ignore BTree.insert(state.serviceSubscriptionIndex2, Principal.compare, subscription.serviceCanister, productSubMap);
        productSubMap;
      };
      case(?val) val;
    };

    let productMap = switch(BTree.get(productSubMap, nullNcompare, subscription.productId)){
      case(null) {
        debug logDebug(debug_channel.subscribe, "Subs: findOrCreateServiceProductMap productMap null" # debug_show(subscription.productId));
        let productMap = BTree.init<Nat,Bool>(null);
        ignore BTree.insert(productSubMap, nullNcompare, subscription.productId, productMap);
        productMap;
      };
      case(?val) val;
    };
    productMap;
  };

  ///MARK: Listeners

  public type NewSubscriptionListener = v0_1_0.NewSubscriptionListener;
  public type ActivateSubscriptionListener = v0_1_0.ActivateSubscriptionListener;
  public type PauseSubscriptionListener = v0_1_0.PauseSubscriptionListener;
  public type CanceledSubscriptionListener = v0_1_0.CanceledSubscriptionListener;
  public type NewPaymentListener = v0_1_0.NewPaymentListener;

  ///MARK: InitArgs


  public type InitArgs =  v0_1_0.InitArgs;

  public type FeeDetail = v0_1_0.FeeDetail;

  ///MARK: environment

  /// `Environment`
  ///
  /// A record that encapsulates various external dependencies and settings that the ledger relies on
  /// for fee calculations, timestamp retrieval, and inter-canister communication.
  /// can_transfer supports evaluating the transfer from both sync and async function.
  public type Environment = v0_1_0.Environment;

  ///MARK: state

  public type State = {
    payments: Map.Map<Nat, v0_1_0.PaymentRecord>;
    payments2: BTreeLib.BTree<Nat, PaymentRecord2>;
    userSubscriptionIndex : UserSubscriptionIndex;
    userSubscriptionIndex2 : UserSubscriptionIndex2;
    serviceSubscriptionIndex : ServiceSubscriptionMap;
    serviceSubscriptionIndex2 : ServiceSubscriptionMap2;
    subscriptions: GlobalSubscriptionMap;
    subscriptions2: GlobalSubscriptionMap2;
    tokenInfo: KnownTokenMap;
    assetInfo: KnownAssetMap;
    notifications: Map.Map<Principal, Map.Map<Nat, Service.ServiceNotification>>;
    recentTrx: Map.Map<Blob, Nat>;
    var publicGoodsAccount: Account;
    var nextSubscriptionId: Nat;
    var nextPaymentId: Nat;
    var nextNotificationId: Nat;
    var exchangeRateCanister: Principal;
    var feeBPS: Nat; //basis points.
    var maxTake: Nat;
    var maxUpdates: Nat;
    var maxQueries: Nat;
    var minDrift: Nat;
    var trxWindow: Nat;
    var defaultTake: Nat;
    var maxMemoSize: Nat;
  };

};