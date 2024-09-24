module {
  public type Value = { #Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text; #Array : [Value]; #Map: [(Text, Value)] };

  public type ICRC16 = {
    #Int :  Int;
    #Int8: Int8;
    #Int16: Int16;
    #Int32: Int32;
    #Int64: Int64;
    #Ints: [Int];
    #Nat : Nat;
    #Nat8 : Nat8;
    #Nat16 : Nat16;
    #Nat32 : Nat32;
    #Nat64 : Nat64;
    #Float : Float;
    #Text : Text;
    #Bool : Bool;
    #Blob : Blob;
    #Class : [{name : Text; value: ICRC16; immutable: Bool}];
    #Principal : Principal;
    #Floats : [Float];
    #Nats: [Nat];
    #Array : [ICRC16];
    #Option : ?ICRC16;
    #Bytes : [Nat8];
    #ValueMap : [(ICRC16, ICRC16)];
    #Map : [(Text, ICRC16)];
    #Set : [ICRC16];
};

  public type Account = { owner : Principal; subaccount : ?Blob };

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

  public type SubscriptionRequest = [[SubscriptionRequestItem]];

  public type SubscriptionRequestItem = {
      #tokenCanister: Principal; // Base token to use to pay the subscription
      #tokenPointer: TokenPointer; // If a multicanister token
      #serviceCanister: Principal; // Service canister to subscribe to
      #interval: Interval; // Interval to pay the subscription
      #amountPerInterval: Nat; // Amount to pay per interval
      #baseRateAsset: (Asset, CheckRate); // Optional: Base rate asset to use to convert the number of tokens to pay. Shoud default to token canister if not specified
      #endDate: Nat; // Optional: Timestamp in nanoseconds to end the subscription
      #targetAccount: Account; //Optional: Account to pay the subscription to, defaults to the service canister default account if not provided
      #productId: Nat; //Optional: Vendor specified product id
      #firstPayment: Nat; //Optional: set a time for the first regular payment.  If not set, the first payment will be immediate
      #nowPayment: Nat; //Optional. set a token amount to process immediately. requires firstPayment to be set and in the future
      #memo: Blob; //Optional: memo to include with the subscription
      #createdAtTime: Nat; //Optional: timestamp for deduplication
      #subaccount: Blob; //Optional: subaccount to use for the subscription
      #broker: Account; //Optional: broker to use for the subscription
  };

  public type SubscriptionRequestItemKeys = {
      #tokenCanister; // Base token to use to pay the subscription
      #tokenPointer; // Optional: for multicanister tokens
      #serviceCanister; // Service canister to subscribe to
      #interval; // Interval to pay the subscription
      #amountPerInterval; // Amount to pay per interval
      #baseRateAsset; // Optional: Base rate asset to use to convert the number of tokens to pay. Shoud default to token canister if not specified
      #endDate; // Optional: Timestamp in nanoseconds to end the subscription
      #targetAccount; //Optional: Account to pay the subscription to, defaults to the service canister default account if not provided
      #productId; //Optional: Vendor specified product id
      #firstPayment; //Optional: set a time for the first regular payment.  If not set, the first payment will be immediate
      #nowPayment; //Optional. set a token amount to process immediately. requires firstPayment to be set and in the future
      #memo; //Optional: memo to include with the subscription
      #createdAtTime; //Optional: timestamp for deduplication
      #subaccount; //Optional: subaccount to use for the subscription
      #broker;
  };

  public type SubscriptionResultItem = ?{
    #Ok: SubscriptionResponse;
    #Err: SubscriptionError;
  };

  public type SubscriptionResult = [SubscriptionResultItem];

  public type SubscriptionResponse = {
      transactionId: Nat;
      subscriptionId: Nat;
  };

  public type PauseRequestItem = {
    subscriptionId : Nat;
    active: Bool;
    reason: Text;
  };

  public type SubscriptionError = {
    #Duplicate;
    #Unauthorized;
    #TokenNotFound;
    #SubscriptionNotFound;
    #FoundActiveSubscription : Nat;
    #InsufficientAllowance : Nat;
    #InsufficientBalance : Nat;
    #InvalidInterval;
    #InvalidDate;
    #Other: {
      code: Nat;
      message: Text;
    };
  };

  public type Asset = { class_ : AssetClass; symbol : Text };
  public type AssetClass = { #Cryptocurrency; #FiatCurrency };
  
  public type ExchangeRate = {
    metadata : ExchangeRateMetadata;
    rate : Nat64;
    timestamp : Nat64;
    quote_asset : Asset;
    base_asset : Asset;
  };

  public type CheckRate = {
    decimals: Nat32;
    rate: Nat64;
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

  public type SubStatus = {
    #Active;
    #WillCancel : (Nat, Principal, Text); //timestamp , caller, reason
    #Canceled : (Nat, Nat, Principal, Text); //request timestamp, cancle date, originalcaller, reason
    #Paused : (Nat, Principal, Text);
  };

  public type SubStatusFilter = {
    #Active;
    #WillCancel;
    #Canceled;
    #Paused;
  };

  public type CancelRequest = {
    subscriptionId: Nat;
  };

  public type CancelResult = ?{
    #Ok: Nat; //transactionId
    #Err: CancelError;
  };

  public type BasicError =  {
    #Unauthorized;
    #Other: {
      code: Nat;
      message: Text;
    };
  };

  public type CancelError = {
    #Unauthorized;
    #NotFound;
    #InvalidStatus: SubStatus;
    #Other: {
      code: Nat;
      message: Text;
    };
  };

  public type PauseError = {
    #Unauthorized;
    #NotFound;
    #InvalidStatus: SubStatus;
    #Other: {
      code: Nat;
      message: Text;
    };
  };

  public type PauseRequest = [PauseRequestItem];


  public type ConfirmResult = ?{
    #Ok: Nat; //subscription info
    #Err: SubscriptionError;
  };

  public type PauseResult = ?{
    #Ok: Nat; 
    #Err: PauseError;
  };


  public type PaymentRecordv0_1_0 = {
    paymentId: Nat;
    date: Nat; // Timestamp of the payment
    amount: Nat;
    fee: ?Nat;
    rate: ?ExchangeRate; // if used
    ledgerTransactionId: ?Nat;
    transactionId: ?Nat;
    feeTransactionId: ?Nat;
    brokerTransactionId: ?Nat;
    brokerFee: ?Nat;
    subscriptionId: Nat;
    result: {
      #Ok;
      #Err: {
        code: Nat;
        message: Text;
      };
    };
  };

  public type PaymentRecord = {
    paymentId: Nat;
    date: Nat; // Timestamp of the payment
    amount: Nat;
    fee: ?Nat;
    rate: ?ExchangeRate; // if used
    ledgerTransactionId: ?Nat;
    transactionId: ?Nat;
    feeTransactionId: ?Nat;
    brokerTransactionId: ?Nat;
    brokerFee: ?Nat;
    account: Account;
    targetAccount: ?Account;
    productId: ?Nat;
    service: Principal;
    subscriptionId: Nat;
    result: {
      #Ok;
      #Err: {
        code: Nat;
        message: Text;
      };
    };
  };

  public type PendingPayment = {
    nextPaymentDate: ?Nat; // Timestamp of the payment
    nextPaymentAmount: ?Nat;
    subscription: Subscription;
  };

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

  public type ServiceNotification = {
      principal: Principal;
      date: Nat; // Timestamp of the notification
      notification: ServiceNotificationType;
  };

  public type UserSubscriptionsFilter = {
    status: ?SubStatusFilter;
    subscriptions: ?[Nat];
    subaccounts: ?[?Blob];
    products: ?[?Nat];
    services: ?[Principal];
  };

  public type ServiceSubscriptionFilter = {
    status: ?SubStatusFilter;
    subscriptions: ?[Nat];
    products: ?[?Nat];
  };

  public type ConfirmRequests = {
    subscriptionId: Nat;
    checkRate: ?CheckRate;
  };

  public type Service = actor {

    icrc79_subscribe : (req: SubscriptionRequest) -> async SubscriptionResult;
    icrc79_cancel_subscription : (req: [{ subscriptionId: Nat; reason: Text }]) -> async [CancelResult];
    icrc79_confirm_subscription : (confirmRequests: [ConfirmRequests]) -> async [ConfirmResult];
    icrc79_pause_subscription : (req: PauseRequest) -> async [PauseResult];

   

    icrc79_get_user_subscriptions : query (filter: ?UserSubscriptionsFilter, prev: ?Nat, take: ?Nat) -> async [Subscription];
    icrc79_get_service_subscriptions : query (service: Principal, filter: ?ServiceSubscriptionFilter, prev: ?Nat, take: ?Nat) -> async [Subscription];
    icrc79_get_user_payments : query (filter: ?UserSubscriptionsFilter, prev: ?Nat, take: ?Nat) -> async [PaymentRecord];
    icrc79_get_service_payments : query (service: Principal, filter: ?ServiceSubscriptionFilter, prev: ?Nat, take: ?Nat) -> async [PaymentRecord];


    icrc79_get_payments_pending : query (subscriptionIds: [Nat]) -> async [?PendingPayment];
    
    icrc79_get_service_notifications : query (service: Principal, prev: ?Nat, take: ?Nat) -> async [ServiceNotification];
    icrc79_metadata : query () -> async [(Text, Value)];
    icrc79_max_query_batch_size : query () -> async Nat;
    icrc79_max_update_batch_size : query () -> async Nat;
    icrc79_default_take_value : query () -> async Nat;
    icrc79_max_take_value : query () -> async Nat;
    icrc79_max_memo_size : query () -> async Nat;
    icrc79_tx_window : query () -> async Nat;
    icrc79_permitted_drift : query  () -> async Nat;
  };

  public type StandardItem = {
    name:Text;
    url: Text;
  };

  public type ICRC10Actor = actor {
    icrc10_supported_standards : query () -> async [StandardItem];
    icrc1_supported_standards : query () -> async [StandardItem];//fallback
  };

  public type GetExchangeRateRequest = {
    timestamp : ?Nat64;
    quote_asset : Asset;
    base_asset : Asset;
  };
  public type GetExchangeRateResult = {
    #Ok : ExchangeRate;
    #Err : ExchangeRateError;
  };

  public type ExchangeRateActor = actor {
    get_exchange_rate : (GetExchangeRateRequest) -> async GetExchangeRateResult;
  };

   public type ICRC1TransferArg = {
    to : Account;
    fee : ?Nat;
    memo : ?Blob;
    from_subaccount : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
  };

  public type Icrc1TransferResult = {
    #Ok : Nat;
    #Err : Icrc1TransferError;
  };

  public type Icrc1TransferError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };

  public type Allowance = {
    allowance : Nat;
    expires_at : ?Nat64;
  };
  public type AllowanceArgs = { account : Account; spender : Account };
  public type ApproveArgs = {
    fee : ?Nat;
    memo : ?Blob;
    from_subaccount : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
    expected_allowance : ?Nat;
    expires_at : ?Nat64;
    spender : Account;
  };
  public type ApproveError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #AllowanceChanged : { current_allowance : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #Expired : { ledger_time : Nat64 };
    #InsufficientFunds : { balance : Nat };
  };
  public type ApproveResult = { #Ok : Nat; #Err : ApproveError };

   public type TransferFromArgs = {
    to : Account;
    fee : ?Nat;
    spender_subaccount : ?Blob;
    from : Account;
    memo : ?Blob;
    created_at_time : ?Nat64;
    amount : Nat;
  };
  public type TransferFromError = {
    #GenericError : { message : Text; error_code : Nat };
    #TemporarilyUnavailable;
    #InsufficientAllowance : { allowance : Nat };
    #BadBurn : { min_burn_amount : Nat };
    #Duplicate : { duplicate_of : Nat };
    #BadFee : { expected_fee : Nat };
    #CreatedInFuture : { ledger_time : Nat64 };
    #TooOld;
    #InsufficientFunds : { balance : Nat };
  };
  public type TransferFromResult = {
    #Ok : Nat;
    #Err : TransferFromError;
  };

  public type ICRC2Actor = actor {
    icrc1_balance_of : shared query Account -> async Nat;
    icrc1_decimals : shared query () -> async Nat8;
    icrc1_fee : shared query () -> async Nat;
    icrc1_metadata : shared query () -> async [(Text, Value)];
    icrc1_minting_account : shared query () -> async ?Account;
    icrc1_name : shared query () -> async Text;
    icrc1_supported_standards : shared query () -> async [
        { url : Text; name : Text }
      ];
    icrc1_symbol : shared query () -> async Text;
    icrc1_total_supply : shared query () -> async Nat;
    icrc1_transfer : shared ICRC1TransferArg -> async Icrc1TransferResult;
    icrc2_allowance : shared query AllowanceArgs -> async Allowance;
    icrc2_approve : shared ApproveArgs -> async ApproveResult;
    icrc2_transfer_from : shared TransferFromArgs -> async TransferFromResult;
  };

  public type TokenPointer = Blob;

  public type ICRC80Actor = actor {
    icrc1_balance_of : shared query Account -> async Nat;
    icrc80_decimals_by_id : shared query (TokenPointer) -> async Nat8;
    icrc80_fee_by_id : shared query (TokenPointer) -> async Nat;
    icrc80_metadata_by_id : shared query (TokenPointer) -> async [(Text, Value)];
    icrc80_minting_account_by_id : shared query (TokenPointer) -> async ?Account;
    icrc80_name_by_id : shared query (TokenPointer) -> async Text;
    icrc10_supported_standards : shared query () -> async [
        { url : Text; name : Text }
      ];
    icrc80_symbol_by_id : shared query (TokenPointer) -> async Text;
    icrc80_total_supply_by_id: shared query (TokenPointer) -> async Nat;
    icrc1_transfer : shared ICRC1TransferArg -> async Icrc1TransferResult;
    icrc2_allowance : shared query AllowanceArgs -> async Allowance;
    icrc2_approve : shared ApproveArgs -> async ApproveResult;
    icrc2_transfer_from : shared TransferFromArgs -> async TransferFromResult;
  };
}