// please do not import any types from your project outside migrations folder here
// it can lead to bugs when you change those types later, because migration types should not be changed
// you should also avoid importing these types anywhere in your project directly from here
// use MigrationTypes.Current property instead

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import D "mo:base/Debug";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import MapLib "mo:map/Map";
import SetLib "mo:map/Set";
import VecLib "mo:vector";
import TTLib "mo:timer-tool";
import Service "../../Service";
/*

import Star "mo:star/star";
 */

module {

  public let Map = MapLib;
  public let Set = SetLib;
  public let Vector = VecLib;
  public let TimerTool = TTLib;

  public type Account = { owner : Principal; subaccount : ?Blob };

  public type Value = { #Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text; #Array : [Value]; #Map: [(Text, Value)] };

  public func isICRC80(token: TokenInfo) : Bool {
    return (Array.indexOf<Text>("ICRC80", token.standards, Text.equal) != null);
  };

  public type Interval = {
      #Hourly;
      #Daily;
      #Weekly;
      #Monthly;
      #Yearly;
      #Interval : Nat; // Interval in nanoseconds
      #Days : Nat;
      #Weeks : Nat;
      #Months : Nat;
  };

  public type Asset = { class_ : AssetClass; symbol : Text };
  public type AssetClass = { #Cryptocurrency; #FiatCurrency };

  public type SubStatus = {
    #Active;
    #WillCancel : (Nat, Principal, Text);
    #Canceled : (Nat, Nat, Principal, Text);
    #Paused : (Nat, Principal, Text);
  };

  public type TokenCanisterPointer = {
    canister: Principal;
    tokenPointer: ?Blob;
  };

  public type SubscriptionState = {
      subscriptionId: Nat;
      tokenCanister: Principal;
      tokenPointer: ?Blob;
      serviceCanister: Principal;
      interval: Interval;
      productId: ?Nat;
      amountPerInterval: Nat;
      brokerId: ?Account;
      baseRateAsset: ?Asset;
      endDate: ?Nat; // Timestamp in nanoseconds to end the subscription
      targetAccount: ?Account;
      account: Account;
      var nextPayment: ?Nat;
      var nextPaymentAmount: ?Nat;
      var nextTimerId: ?TTLib.ActionId;
      var status: SubStatus;
      history: VecLib.Vector<Nat>; //holds transaction id of each item associated with this sub
  };

  public type CheckRate = {
    decimals: Nat32;
    rate: Nat64;
  };

  public type SubscriptionStateShared = {
      subscriptionId: Nat;
      tokenCanister: Principal;
      tokenPointer: ?Blob;
      serviceCanister: Principal;
      interval: Interval;
      productId: ?Nat;
      amountPerInterval: Nat;
      baseRateAsset: ?Asset;
      brokerId: ?Account;
      checkRate: ?CheckRate;
      endDate: ?Nat; // Timestamp in nanoseconds to end the subscription
      targetAccount: ?Account;
      account: Account;
      nextPayment: ?Nat;
      memo: ?Blob;
      createdAt: ?Nat;
      nextPaymentAmount: ?Nat;
      nextTimerId: ?TTLib.ActionId;
      status: SubStatus;
      history: [Nat]; //holds payment id of each item associated with this sub
  };

  public func shareSubscriptionState(sub: SubscriptionState) : Service.Subscription {
    return {
      subscriptionId = sub.subscriptionId;
      tokenCanister = sub.tokenCanister;
      tokenPointer = sub.tokenPointer;
      serviceCanister = sub.serviceCanister;
      interval = sub.interval;
      productId = sub.productId;
      amountPerInterval = sub.amountPerInterval;
      baseRateAsset = sub.baseRateAsset;
      brokerId = sub.brokerId;
      endDate = sub.endDate;
      targetAccount = sub.targetAccount;
      account = sub.account;
      nextPayment = sub.nextPayment;
      nextPaymentAmount = sub.nextPaymentAmount;
      status = sub.status;
      history = sub.history;
    };
  };

  public type ProductSubscriptionMap = MapLib.Map<?Nat, Set.Set<Nat>>;
  public type ServiceSubscriptionMap = MapLib.Map<Principal, ProductSubscriptionMap>;
  public type SubAccountSubscriptionMap = MapLib.Map<Blob, ServiceSubscriptionMap>;
  public type UserSubscriptionIndex = MapLib.Map<Principal, SubAccountSubscriptionMap>;

  public type ServiceSubscriptionIndex = MapLib.Map<Principal, ProductSubscriptionMap>;




  public type GlobalSubscriptionMap = MapLib.Map<Nat, SubscriptionState>;


  public type ScheduledPaymentArgs = {
    subscriptionId : Nat;
    amountAtSet: Nat;
    timeAtSet: Nat;
    retries: Nat;
  };


  ///MARK: Interceptors
  public type CanAddSubscription = ?((SubscriptionState, Value, Value) -> Result.Result<(SubscriptionState, Value, Value), Service.SubscriptionError>);


  public type TokenInfo = {
    tokenCanister: Principal;
    tokenSymbol: Text;
    tokenDecimals: Nat8;
    tokenPointer: ?Nat;
    tokenFee: ?Nat;
    tokenTotalSupply: Nat;
    standards: [Text];
  };

  public type KnownTokenMap = MapLib.Map<(Principal,?Blob), TokenInfo>;

  public type KnownAssetMap = SetLib.Set<Asset>;

  

  public type ServiceNotificationType = {
    
    #AllowanceInsufficient: {
      principal: Principal;
      subscriptionId: Nat;
    };
    #LedgerError: {
      error: Text;
      rescheduled: ?Nat;
      subscriptionId: Nat;
    };
    #SubscriptionEnded: {
      principal: Principal;
      subscriptionId: Nat;
      reason: Text;
    };
    #SubscriptionPaused: {
      principal: Principal;
      subscriptionId: Nat;
      reason: Text;
    };
    #SubscriptionActivated: {
      principal: Principal;
      subscriptionId: Nat;
      reason: Text;
    };
    #ExchangeRateError: {
      rate: ExchangeRate;
      subscriptionId: Nat;
      rate_error: ?ExchangeRateError;
      reason: ?Text;
    };
  };

  
  public type ExchangeRate = {
    metadata : ExchangeRateMetadata;
    rate : Nat64;
    timestamp : Nat64;
    quote_asset : Asset;
    base_asset : Asset;
  };

  public type ExchangeRateError = {
    #AnonymousPrincipalNotAllowed;
    #CryptoQuoteAssetNotFound;
    #FailedToAcceptCycles;
    #ForexBaseAssetNotFound;
    #CryptoBaseAssetNotFound;
    #StablecoinRateTooFewRates;
    #ForexAssetsNotFound;
    #InconsistentRatesReceived;
    #RateLimited;
    #StablecoinRateZeroRate;
    #Other : { code : Nat32; description : Text };
    #ForexInvalidTimestamp;
    #NotEnoughCycles;
    #ForexQuoteAssetNotFound;
    #StablecoinRateNotFound;
    #Pending;
  };
  public type ExchangeRateMetadata = {
    decimals : Nat32;
    forex_timestamp : ?Nat64;
    quote_asset_num_received_rates : Nat64;
    base_asset_num_received_rates : Nat64;
    base_asset_num_queried_sources : Nat64;
    standard_deviation : Nat64;
    quote_asset_num_queried_sources : Nat64;
  };

  public type ServiceNotification = {
      principal: Principal;
      date: Nat; // Timestamp of the notification
      notification: ServiceNotificationType;
  };

  public type PaymentRecord = {
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
    result: {
      #Ok;
      #Err: {
        code: Nat;
        message: Text;
      };
    };
  };

  

  /// `Stats`
  ///
  /// Represents collected statistics about the ledger, such as the total number of accounts.
  public type Stats = {
    services: Nat;
    subscriptions: Nat;
    activeSubscriptions: Nat;
  };

  public func subAccountEqual(a : ?Blob, b : ?Blob) : Bool{
    switch(a, b){
      case(null, null) return true;
      case(?vala, ?valb){
        vala == valb;
      };
      case(null,?val){
        if(not(nullSubaccount == val)){
          return false;
        };
        return true;
      };
      case(?val,null){
        if(not(nullSubaccount == val)){
          return false;
        };
        return true;
      };
    };
  };

  public func knownTokenHash32(a : (Principal, ?Blob)) : Nat32{
    var accumulator = MapLib.phash.0(a.0);
    switch(a.1){
      case(null){
        accumulator +%= MapLib.thash.0("null");
      };
      case(?val){
        accumulator +%= MapLib.bhash.0(val);
      };
    };
    return accumulator;
  };

  public func knownTokenEq(a : (Principal, ?Blob), b : (Principal, ?Blob)) : Bool{
    
    if(a.0 != b.0) return false;
    if(a.1 != b.1) return false;
    return true;
  };

    public func knownTokenCompare(a : (Principal, ?Blob), b : (Principal, ?Blob)) : Order.Order {
    if(a.0 == b.0){
      switch(a.1, b.1){
        case(null, null) return #equal;
        case(?vala, ?valb) return Blob.compare(vala,valb);
        case(null, ?valb){
         return #less;
        };
        case(?vala, null){
          return #greater;
        }
      };
    } else return Principal.compare(a.0, b.0);
  };

  public let ktHash = (knownTokenHash32, knownTokenEq);

  public func assetHash32(a : Asset) : Nat32{
    var accumulator = MapLib.thash.0(a.symbol);
    switch(a.class_){
      case(#FiatCurrency){
        accumulator +%= MapLib.thash.0("fiat");
      };
      case(#Cryptocurrency){
        accumulator +%= MapLib.thash.0("crypto");
      };
    };
    return accumulator;
  };

  public func assetEq(a :Asset, b : Asset) : Bool{
    
    if(a.class_ != b.class_) return false;
    if(a.symbol != b.symbol) return false;
    return true;
  };

    public func assetCompare(a :Asset, b : Asset) : Order.Order {
    if(a.class_ == b.class_){
      Text.compare(a.symbol, b.symbol);
    } else {
      switch(a.class_, b.class_){
        case(#FiatCurrency, #Cryptocurrency) return #less;
        case(#Cryptocurrency, #FiatCurrency) return #greater;
        case(_, _) return #equal; //unreachable
      };
    };
  };

  public let assetHash = (assetHash32, assetEq);

  public func nullNHash32(a : ?Nat) : Nat32{
    let ?ab = a else return 3934983493;
    return MapLib.nhash.0(ab);
  };

  public func nullNeq(a : ?Nat, b : ?Nat) : Bool{
    if(a != b) return false;
    return true;
  };

    public func nullNcompare(a : ?Nat, b : ?Nat) : Order.Order {
    if(a == b) return #equal;
    switch(a, b){
      case(null, null) return #equal;
      case(?vala, ?valb) return Nat.compare(vala,valb);
      case(null, ?valb){
        return #less;
      };
      case(?vala, null){
        return #greater;
      }
    };
  };

  public let nullNHash = (nullNHash32, nullNeq);



  /// `accountHash32`
  ///
  /// Produces a 32-bit hash of an `Account` for efficient storage or lookups.
  ///
  /// Parameters:
  /// - `a`: The `Account` to hash.
  ///
  /// Returns:
  /// - `Nat32`: A 32-bit hash value representing the account.
  public func accountHash32(a : Account) : Nat32{
    var accumulator = MapLib.phash.0(a.owner);
    switch(a.subaccount){
      case(null){
        accumulator +%= MapLib.bhash.0(nullSubaccount);
      };
      case(?val){
        accumulator +%= MapLib.bhash.0(val);
      };
    };
    return accumulator;
  };

  public let nullSubaccount  : Blob = "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00";

  /// `accountEq`
  ///
  /// Compares two `Account` instances for equality.
  ///
  /// Parameters:
  /// - `a`: First `Account` to compare.
  /// - `b`: Second `Account` to compare.
  ///
  /// Returns:
  /// - `Bool`: True if accounts are equal, False otherwise.
  public func accountEq(a : Account, b : Account) : Bool{
    
    if(a.owner != b.owner) return false;
    switch(a.subaccount, b.subaccount){
      case(null, null){};
      case(?vala, ?valb){
        if(vala != valb) return false;
      };
      case(null,?val){
        if(not(nullSubaccount == val)){
          return false;
        }
      };
      case(?val,null){
        if(not(nullSubaccount == val)){
          return false;
        }
      };
    };
    return true;
  };

  /// `accountCompare`
  ///
  /// Orders two `Account` instances.
  ///
  /// Parameters:
  /// - `a`: First `Account` to compare.
  /// - `b`: Second `Account` to compare.
  ///
  /// Returns:
  /// - `Order.Order`: An ordering indication relative to the accounts.
  public func accountCompare(a : Account, b : Account) : Order.Order {
    if(a.owner == b.owner){
      switch(a.subaccount, b.subaccount){
        case(null, null) return #equal;
        case(?vala, ?valb) return Blob.compare(vala,valb);
        case(null, ?valb){
          if(valb == nullSubaccount) return #equal;
         return #less;
        };
        case(?vala, null){
          if(vala == nullSubaccount) return #equal;
          return #greater;
        }
      };
    } else return Principal.compare(a.owner, b.owner);
  };

  public let ahash = (accountHash32, accountEq);

  ///MARK: Listeners

  public type NewSubscriptionListener = <system>(SubscriptionState, trxId: Nat) -> ();
  public type ActivateSubscriptionListener = <system>(SubscriptionState, trxId: Nat) -> ();
  public type PauseSubscriptionListener = <system>(SubscriptionState, trxId: Nat) -> ();
  public type CanceledSubscriptionListener = <system>(SubscriptionState, trxId: Nat) -> ();
  public type NewPaymentListener = <system>(SubscriptionState, PaymentRecord, trxId: Nat) -> ();

  ///MARK: InitArgs


  public type InitArgs = {
    publicGoodsAccount: ?Account;
    nextSubscriptionId: ?Nat;
    nextPaymentId: ?Nat;
    nextNotificationId: ?Nat;
    existingSubscriptions: [SubscriptionStateShared];
    tokenInfo: ?[((Principal,?Blob), TokenInfo)];
    feeBPS: ?Nat;
    maxTake: ?Nat;
    maxUpdates: ?Nat;
    maxQueries: ?Nat;
    minDrift: ?Nat;
    trxWindow: ?Nat;
    defaultTake: ?Nat;
    maxMemoSize: ?Nat;
  };

  public type FeeDetail = {
    service: Principal;
    targetAccount: ?Account;
    subscribingAccount: Account;
    feeAccount: Account;
    token: (Principal,?Blob);
    feeAmount: Nat;
  };

  ///MARK: environment

  /// `Environment`
  ///
  /// A record that encapsulates various external dependencies and settings that the ledger relies on
  /// for fee calculations, timestamp retrieval, and inter-canister communication.
  /// can_transfer supports evaluating the transfer from both sync and async function.
  public type Environment = {
    addLedgerTransaction: ?(<system>(Value, ?Value) -> Nat);
    tt: TTLib.TimerTool;
    canSendFee: ?((FeeDetail) -> Bool); 
    advanced: ?{
      icrc85 : ?{
        kill_switch: ?Bool;
        handler: ?(([(Text, [(Text, Value)])]) -> ());
        period: ?Nat;
        asset: ?Text;
        platform: ?Text;
        tree: ?[Text];
        collector: ?Principal;
      };
    };
  };

  ///MARK: state

  public type State = {
    payments: Map.Map<Nat, PaymentRecord>;
    userSubscriptionIndex : UserSubscriptionIndex;
    serviceSubscriptionIndex : ServiceSubscriptionMap;
    subscriptions: GlobalSubscriptionMap;
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