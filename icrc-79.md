# ICRC-79: Secure Subscription Canister Standard

|ICRC|Title|Author|Discussions|Status|Type|Category|Created|
|:----:|:----:|:----:|:----:|:----:|:----:|:----:|:----:|
|79|Secure Subscription Canister Standard|spudsubs @spudsubs|https://github.com/dfinity/ICRC/issues/79|Draft|Standards Track|Financial|2023-XX-XX|

## Data Types Definition

This section outlines the core data types utilized in the ICRC-79 standard, facilitating the description and structuring of data relevant to secure subscription canisters.


### Subscription

Each subscription is uniquely defined by the following attributes, capturing the necessary details for managing periodic payment requests under various configurations.

```candid
type Interval = variant {
    Hourly;
    Daily;
    Weekly;
    Monthly;
    Yearly;
    Interval : nat; // Interval in nanoseconds
    Days : nat;
    Weeks : nat;
    Months : nat;
};

  type SubscriptionRequest = [SubscriptionRequestItem];
  type CheckRate = {
    decimals: Nat32;
    rate: Nat64;
  };


  type SubscriptionRequestItem = variant {
      tokenCanister: Principal; // Base token to use to pay the subscription
      tokenPointer: Blob; //icrc80 token pointer
      serviceCanister: Principal; // Service canister to subscribe to
      interval: Interval; // Interval to pay the subscription
      amountPerInterval: Nat; // Amount to pay per interval
      baseRateAsset: (Asset, CheckRate); // Optional: Base rate asset to use to convert the number of tokens to pay per interval. Check Rate is a modifier to use to modify the amountPerInterval during the initial subscription check
      endDate: Nat; // Optional: Timestamp in nanoseconds to end the subscription
      targetAccount: Account; //Optional: Account to pay the subscription to, defaults to the service canister default account if not provided
      productId: Nat; //Optional: Vendor specified product id
      ICRC17Endpoint: Principal; // Optional KYC validation endpoint
      firstPayment: Nat; //Optional: set a time for the first regular payment.  If not set, the first payment will be immediate
      nowPayment: Nat; //Optional. set a token amount to process immediately. If first payment is set this will cause immediate payment of this amount.
      memo: Blob; //Optional: memo to include with the subscription
      create_at_time: Nat; //Optional: timestamp for deduplication
      subaccount: Blob; //Optional: subaccount to use for the subscription
  };

  public type SubscriptionRequestItemKeys = variant {
      tokenCanister;
      serviceCanister;
      interval;
      amountPerInterval; 
      baseRateAsset;
      endDate;
      targetAccount;
      productId;
      ICRC17Endpoint;
      firstPayment;
      nowPayment;
      memo;
      create_at_time;
      subaccount;
  };

type SubscriptionResult = variant {
  Ok: SubscriptionResponse;
  Err: SubscriptionError;
}

type SubscriptionResponse = record {
    transactionId: nat;
    subscriptionId: nat;
};

type SubscriptionError = variant {
  Unauthorized;
  TokenNotFound;
  Duplicate; //due to async nature, can't provide id
  SubscriptionNotFound;
  InsufficientAllowance : nat;
  InvalidDate;
  InvalidInterval;
  ICRC17Error: KYCResult;
  Other: {
    code: nat;
    message: text;
  };
};

type AssetClass = variant { Cryptocurrency; FiatCurrency; };

type Asset = record {
    symbol: text;
    class: AssetClass;
};

// The parameters for the `get_exchange_rate` API call.
type ExchangeRate = record {
    base_asset: Asset;
    quote_asset: Asset;
    min_recieved_base:  opt nat64;
    min_recieved_quote:  opt nat64;
    max_standard_deviation :  opt nat64;
};

type ExchangeRateResult = record {
    base_asset: Asset;
    quote_asset: Asset;
    timestamp: nat64;
    rate: nat64;
    metadata: ExchangeRateMetadata;
};

type ExchangeRateError = variant {
    // Returned when the canister receives a call from the anonymous principal.
    AnonymousPrincipalNotAllowed: null;
    /// Returned when the canister is in process of retrieving a rate from an exchange.
    Pending: null;
    // Returned when the base asset rates are not found from the exchanges HTTP outcalls.
    CryptoBaseAssetNotFound: null;
    // Returned when the quote asset rates are not found from the exchanges HTTP outcalls.
    CryptoQuoteAssetNotFound: null;
    // Returned when the stablecoin rates are not found from the exchanges HTTP outcalls needed for computing a crypto/fiat pair.
    StablecoinRateNotFound: null;
    // Returned when there are not enough stablecoin rates to determine the forex/USDT rate.
    StablecoinRateTooFewRates: null;
    // Returned when the stablecoin rate is zero.
    StablecoinRateZeroRate: null;
    // Returned when a rate for the provided forex asset could not be found at the provided timestamp.
    ForexInvalidTimestamp: null;
    // Returned when the forex base asset is found.
    ForexBaseAssetNotFound: null;
    // Returned when the forex quote asset is found.
    ForexQuoteAssetNotFound: null;
    // Returned when neither forex asset is found.
    ForexAssetsNotFound: null;
    // Returned when the caller is not the CMC and there are too many active requests.
    RateLimited: null;
    // Returned when the caller does not send enough cycles to make a request.
    NotEnoughCycles: null;
    // Returned when the canister fails to accept enough cycles.
    FailedToAcceptCycles: null;
    /// Returned if too many collected rates deviate substantially.
    InconsistentRatesReceived: null;
    // Until candid bug is fixed, new errors after launch will be placed here.
    Other: record {
        // The identifier for the error that occurred.
        code: nat32;
        // A description of the error that occurred.
        description: text;
    }
};

type KYCResult = 
 record {
   aml: variant {
          Fail;
          NA;
          Pass;
        };
   amount: opt nat;
   kyc: variant {
          Fail;
          NA;
          Pass;
        };
   message: opt text;
   extensible: opt CandyShared;
   token: opt TokenSpec;
   timeout: opt nat;
 };

type Subscription = record {
    subscriptionId: nat;
    tokenCanister: principal;
    tokenPointer: ?Blob;
    serviceCanister: Principal;
    interval: Interval;
    amountPerInterval: nat;
    exchangeRate: opt ExchangeRate;
    endDate: opt nat; // Timestamp in nanoseconds to end the subscription
    targetAccount: ?Account;
    ICRC17Endpoint: opt principal; // Optional KYC validation endpoint
    productId: opt nat;
    account: Account;
    nextPayment: opt nat;
    nextPaymentAmount: opt nat;
    status: SubStatus;
};

type SubStatus = variant {
  Active;
  WillCancel: (nat, principal, text); //request timestamp, caller, reason
  Canceled : (nat, nat, principal, text); //request timestamp, caller, reason
  Paused : (nat, principal); //timestamp, caller
};

type CancelRequest = vec CancelRequestItem

type CancelRequestItem = record {
  subscriptionId: subscriptionId;
  reason: Text
};

type CancelResult = vec  opt variant {
  Ok: nat; //transactionId
  Err: CancelError;
};

type BasicError =  variant {
  Unauthorized;
  Other: {
    code: nat;
    message: text;
  };
};

type CancelError = BasicError;

type PauseRequest = record {
  subscriptionId: subscriptionId;
};

type PauseError = BasicError;

```

### Account

An account, identified by a principal and optionally a specific subaccount, is used to define the destination for transferred funds.

```candid
type Subaccount = blob;
type Account = record {
    owner: principal;
    subaccount: opt Subaccount;
};
```

### Payment History Record

Historical payment transactions are recorded using this structure, ensuring transparency and access to past subscription activity.

```candid
type PaymentRecord = record {
    paymentId: nat;
    date: nat; // Timestamp of the payment
    amount: nat;
    fee: opt nat;
    rate: opt ExchangeRateResult; // if used
    ledgerTransactionId: nat;
    transactionId: nat;
    feeTransactionId: opt nat;
    subscriptionId: nat;
    result: Bool;
};
```

### Pending Payment History Record

Future payment using this structure, ensuring transparency and access to future pending payments.

```candid
type PendingPayment = record {
    nextPaymentDate: nat; // Timestamp of the payment
    nextPaymentAmount: nat;
    subscription: Subscription;
};
```
//todo: move notifications out of the standard and move them to an indexing server
### ServiceNotification

When the system has an issue it needs to notify a service provider of it will create a service notification.

```candid

type ServiceNotificationType = variant {
  CustomerEndedSubscription: record {
    principal: principal;
    subscriptionId: nat;
    reason: text;
  };
  AllowanceInsufficient: record {
    principal: principal;
    subscriptionId: nat;
  };
  LedgerError: record {
    error: text;
    rescheduled: opt nat;
    subscriptionId: nat;
  };
  ServiceEndedSubscription: record {
    principal: principal;
    subscriptionId: nat;
    reason: text;
  };
  ExchangeRateError: record {
    rate: ExchangeRate;
    subscriptionId: nat;
    rate_error: opt ExchangeRateError;
    reason: opt Text;
  };
};

type ServiceNotification = record {
    principal: principal;
    date: nat; // Timestamp of the notification
    notification: ServiceNotificationType;
};
```

### Exchange Rate Integration in Subscriptions

#### Overview

Integrating dynamic exchange rate capabilities into the subscription model is crucial for supporting services and transactions that involve different assets, especially in a globally distributed network like the Internet Computer. The exchange rate feature leverages the Exchange Rate Canister (XRC) to ensure that subscriptions maintain accurate and fair pricing when converting between various cryptocurrencies and fiat currencies.

#### Exchange Rate Canister (XRC) Utilization

The Exchange Rate Canister provides real-time and historical asset exchange rates, accommodating an array of asset pairings such as cryptocurrencies to fiat currencies or between different cryptocurrencies. When a subscription involves payments in different currencies from the base asset, the subscription canister retrieves current or historical exchange rates using the XRC.

Find more about the Exchange rate canister here:  https://wiki.internetcomputer.org/wiki/Exchange_rate_canister


#### Workflow
   
1. **Recurring Payment Processing with Dynamic Rates**: For each billing cycle, the subscription canister checks if the payment requires conversion using updated exchange rates. If so, it requests the current rate from the XRC right before processing the payment. This ensures that the amount transferred is based on the latest available exchange rate, providing fairness both to the service provider and the subscriber.

2. **Handling Exchange Rate Volatility**: To manage exchange rate fluctuations, the subscription can optionally set thresholds for acceptable rates and standard deviations. If the fetched rate does not satisfy these conditions (e.g., if the rate's standard deviation is too high, indicating significant volatility), the subscription canister might pause the transaction and notify the subscriber and service provider to confirm the transaction manually or adjust the terms.

4. **Historical Rates for Audit and Reconciliation**: For audit and record-keeping purposes, subscriptions can store historical rates used for each transaction. This facilitates transparency and simplifies reconciliation during financial audits.

#### Error Management

When the XRC response contains an error (e.g., due to an invalid asset pair request or network issues), the subscription canister handles this by either retrying the request, pausing the subscription, or notifying the subscriber and service provider based on the error type and predefined handling protocols.

### Intervals

Intervals define the frequency at which payments are processed for a subscription. The ICRC-79 standard supports various predefined intervals and allows for custom-defined periods. The interval determines the recurring payment cycle for the subscription, automating the transfer of the specified `amountPerInterval` from the subscriber's account to the service provider's target account.

### Interval Types

The ICRC-79 standard supports the following interval types, each corresponding to common temporal patterns for subscription services:

1. **Hourly**: Payments are processed every hour. 3_600_000_000_000 nanoseconds.
2. **Daily**: Payments are processed every day. 86_400_000_000_000 nanoseconds.
3. **Weekly**: Payments are processed every week. 604_800_000_000_000
4. **Monthly**: Payments are processed every month. A month is considered to be 30.4375 days such that every 4 years there are exactly 48 payments. 2_629_800_000_000_000 nanoseconds
5. **Yearly**: Payments are processed every year. A year is considered to be 365.25 days such that every 4 years there are exactly 4 payments. 31_557_600_000_000_000 nanoseconds
6. **Interval (nat)**: Custom interval defined in nanoseconds.
7. **Days (nat)**: Custom interval that allows subscribers to specify payments to be processed every 'n' days.
8. **Weeks (nat)**: Custom interval that allows subscribers to specify payments to be processed every 'n' weeks.
9. **Months (nat)**: Custom interval that allows subscribers to specify payments to be processed every 'n' months.

### First Payment Consideration

Optionally, a `firstPayment` timestamp can be set to delay the start of the subscription interval. If set, the first interval will commence at this specified time, otherwise, it will begin immediately upon subscription activation.  This value is in UTC nanoseconds. If it is set in the past the subscription should initiate immediately.

### Example

Here is an example of how to define a subscription with a custom weekly interval:

```candid
let subscriptionRequest = {
    tokenCanister: principal "rrkah-fqaaa-aaaaa-aaaaq-cai";
    serviceCanister: principal "rwlgt-iiaaa-aaaaa-aaaaa-cai";
    interval: variant {Weeks =2}; // Payment every 2 weeks
    amountPerInterval: 50;
    endDate: opt null;
    targetAccount: {...};
    productId: opt 123;
    ICRC17Endpoint: opt null;
    firstPayment: opt null;
    memo: blob "New Subscription";
    create_at_time: Nat64.now();
    subaccount: opt null
};
```

In this example, the subscription is configured to charge 50 tokens every two weeks from the subscriber's account to the specified target account. The interval setting, alongside other subscription parameters, helps in tailoring the subscription mechanism to meet diverse business and operational needs.

## Methods

Please see the Batch Update Methods, Batch Query Methods, Error Handling, and Other Aspects sections of the ICRC-7 standard for important information about the ICRC-79 approach to methods and return types.

### Update methods

The following Candid definitions describe the ICRC-79 standard's messages used to manipulate the subscription lifecycle. These include creating, confirming, and canceling subscriptions.

#### `icrc79_subscribe`

Creates a new subscription based on the data provided by the `SubscriptionRequest`. This function must be called by the subscribing principal, specifying a subaccount that has a valid approval for the expected amount.

```candid
icrc79_subscribe: (SubscriptionRequest) -> (SubscriptionResult);
```

#### `icrc79_cancel_subscription`

Allows the cancellation of an existing subscription. This function can be called by either the service provider or the user account to terminate a subscription.

```candid
icrc79_cancel_subscription: (vec record { subscriptionId: nat; reason: text}) -> (CancelResult);
```

### `icrc79_confirm_subscription`

This function can be triggered by the service provider to force verification of the allowance. It ensures that the funds are still available as per the parameters of the subscription.

```candid
icrc79_confirm_subscription: (vec nat) -> (vec ConfirmResult);
```

#### `icrc79_pause_subscription`

Allows the pausing of an existing subscription by either the service provider or the user. This function can be called by either the service provider or the user account to pause a subscription.

```candid
type PauseRequestItem = record {
  subscriptionId: nat;
  reason: text;
  active: bool;
};

type PauseResultItem = opt variant {
  Ok: Nat; //trx id
  Err: PauseError;
};

icrc79_pause_subscription: (vec PauseRequestItem) -> (vec PauseResultItem);
```

The array of tuples submitted are made up of the subscriptionId and the desired active state(true/false);

### Query Methods

These Candid definitions specify the query methods used in ICRC-79 for retrieving information about subscriptions, payments, and payments pending. These methods provide read-only access to the subscription data stored within the canister.

#### `icrc79_get_user_subscriptions`

This method retrieves a list of subscriptions associated with the calling user. It can optionally filter results based on the status of the subscriptions and supports pagination through `prev` and `take` parameters.

```candid

type UserSubscriptionsFilter = record {
    status: opt SubStatusFilter;
    subscriptions: opt vec nat;
    subaccounts: opt vec opt blob;
    products: opt vec opt nat;
    services: opt vec Principal;
  };

icrc79_get_user_subscriptions: (filter: opt UserSubscriptionsFilter, prev: opt nat, take: opt nat) : async vec Subscription;
```

#### `icrc79_get_service_subscriptions`

Retrieves a list of all subscriptions managed by a service provider through the canister. This method allows filtering by product ID and supports pagination.

```candid
  type SubStatusFilter = {
    #Active;
    #WillCancel;
    #Canceled;
    #Paused;
  };

  type ServiceSubscriptionsFilter = record {
    status: opt SubStatusFilter;
    subscriptions: opt vec nat;
    subaccounts: opt vec opt blob;
    products: opt vec opt nat;
  };

  icrc79_get_service_subscriptions: (service: Principal, filter: opt ServiceSubscriptionsFilter, prev: opt nat, take: opt nat) -> async vec Subscription;
```

### `icrc79_get_user_payments`

Allows a user to retrieve a detailed list of past payments related to their subscriptions. This method can filter by specific subscription IDs and also supports pagination.

```candid
icrc79_get_user_payments: (filter: opt UserSubscriptionsFilter, prev: opt nat, take: opt nat) -> async vec PaymentRecord;
```

#### `icrc79_get_user_payments_pending`

Retrieves pending payments for a user's subscriptions, which can be filtered by specific subscription IDs, with support for pagination.

```candid
icrc79_get_user_payments_pending: (subscriptions: vec nat) -> async vec PendingPayment;
```

### `icrc79_get_service_payments`

Enables a service provider to access a list of past payments received for provided services, filterable by specific subscription IDs and supporting pagination.

```candid
icrc79_get_service_payments: (service:Principal, filter: opt ServiceSubscriptionsFilter, prev: opt nat, take: opt nat) -> async vec PaymentRecord;
```

#### `icrc79_get_service_notifications`

Allows a service provider to fetch notifications related to the subscriptions under their management. Supports pagination.

```candid
icrc79_get_service_notifications: (prev: opt nat, take: opt nat) -> async vec ServiceNotification;
```

## ICRC-79 Block Schema

ICRC-79 expands on the ICRC-3 specification for defining the format for storing transactions in blocks of the log of the subscription ledger. Below, we define the concrete block schema for ICRC-79 as an extension of the ICRC-3 block schema. This schema must be implemented by a ledger implementing ICRC-79 if it claims to align its logs with ICRC-3 through the method listing the supported standards.

//todo: Since the create action is async, do we need a request action that is logged immediately to indicate that an action is underway?

#### Subscription Creation Block Schema

1. **Block Type (`btype`):** `"subCreate"`
2. **Transaction (`tx`) Contents:**
   - `subscriptionId: Value.Nat` - Identifier of the new subscription.
   - `creator: Value.Principal` - Principal ID of the user initiating the subscription.
   - `tokenCanister: Value.Principal` - Principal ID of the canister managing the tokens.
   - `interval: Value.Text` - Subscription interval details in descriptive text.
   - `intervalAmt: Value.Nat` - Subscription interval count if applicable.
   - `amtPerInterval: Value.Nat` - Tokens transferred per interval.
   - `endDate: Value.Opt(Value.Nat)` - Optional timestamp of when the subscription should end.
   - `targetAccount: Value.Array([Value.Blob,?Value.Blob]` - Serialized account to which tokens are sent.
   - `icrc17: Value.Opt(Value.Principal)` - Optional principal of the ICRC-17 KYC endpoint.
   - `status: Value.Text` - Initial status of the subscription.
   - `memo: Value.Opt(Value.Text)` - Optional additional information about the subscription.
   - `createdAt: Value.Nat` - Timestamp of when the subscription was created.

#### Subscription Cancel Block Schema

1. **Block Type (`btype`):** `"subCancel"`
2. **Transaction (`tx`) Contents:**
   - `subscriptionId: Value.Nat` - Identifier of the canceled subscription.
   - `canceller: Value.Principal` - Principal ID of the user or service that canceled the subscription.
   - `cancelReason: Value.Text` - Text reason or code indicating why the subscription was canceled.
   - `canceledAt: Value.Nat` - Timestamp of cancellation.

#### Subscription Status Change Block Schema

1. **Block Type (`btype`):** `"SubscriptionStatusUpdate"`
2. **Transaction (`tx`) Contents:**
   - `subscriptionId: Value.Nat` - Identifier of the subscription.
   - `caller: Value.Principal` - Principal ID of the user or service that made the status change.
   - `statusReason: Value.Text` - Text reason for the status change.
   - `newStatus: Value.Text` - New status of the subscription.
   - `changeAt: Value.Nat` - Timestamp of the status change.

#### Payment Transaction Block Schema

1. **Block Type (`btype`):** `"PaymentTransaction"`
2. **Transaction (`tx`) Contents:**
   - `trxID: Value.Nat` - Unique identifier of the payment on the token ledger.
   - `subscriptionId: Value.Nat` - Related subscription identifier.
   - `amount: Value.Nat` - Amount of tokens transferred.
   - `rate: Value.Nat` - Optional - Rate if it was used.
   - `rateBase: Value.Text - Optional - Symbol of the exchange rate used if present.
   - `ledgerTransactionId: Value.Nat` - Reference ID in the token ledger.
   - `tokenLedger: Value.Blob` - Principal of the token ledger.
   - `tokenPointer: Value.Blob` - Optional. Principal of the token pointer.
   - `paymentDate: Value.Nat` - Date and time when the payment was processed.
   - `feeTransactionId: Value.nat` - Pointer to the fee trx id:


#### Notification Block Schema

1. **Block Type (`btype`):** `"SubscriptionNotification"`
2. **Transaction (`tx`) Contents:**
   - `notificationId: Value.Nat` - Unique identifier for the notification.
   - `subscriptionId: Value.Nat` - Identifier of the related subscription.
   - `principal: Value.Principal` - Principal ID receiving the notification.
   - `message: Value.Text` - Content of the notification.
   - `notificationDate: Value.Nat` - Timestamp when the notification was generated.

Each block within the transaction log of the ICRC-79 ledger ensures that the state of any subscription can be effectively reconstructed, optimizing transparency, auditability, and reliability of the subscription services provided on the Internet Computer.

### Determining Token Approval Amount

Determining the correct amount of tokens to approve for a subscription canister is critical to ensure smooth operation of the subscription mechanism while maintaining high security and user confidence. The ICRC-79 standard describes a method to effectively and securely establish the token approval amount required for a subscription through interactions with ICRC-1 and ICRC-2 standards.

#### Various Conditional Approval Scenarios

1. **Initial Approval using ICRC-1 Total Supply Query:**
    - Initially, when a user sets up a subscription, it is ideal to pre-approve an amount that is significantly higher than the periodic payment to minimize transaction costs and approval operations. The ICRC-79 standard suggests querying the `icrc1_total_supply` to understand the maximum potential tokens available.
    - From this total supply, the standardized approach is to set the approval amount to 50% of the total token supply. This might seem extensive, but since the subscription contract adheres to a blackholed, open-sourced code execution model that strictly conforms to pre-defined behaviors, it effectively mitigates the risk of any malicious deductions beyond the agreed subscription amounts.

2. **Fallback to Wallet Balance:**
    - If for any reason, such as the token implementation having a max approval amount or not allowing an approval beyond a user's balance, the initial method to query the total supply fails, the next reliable source is the user’s wallet balance.
    - The subscription setup should query the user's current token balance and set this balance, minus a fee,  as the approval limit. This ensures that even in fallback scenarios, the subscription proceeds without inadvertently causing account overdrafts. However, this method automatically adjusts the maximum ceiling for potential payment disruptions if the wallet balance is lower than the expected subscription fees.
    - If the wallet’s current balance does not cover the upcoming subscription fee, the process should cease with an error, and the subscription setup should not proceed. This safeguard prevents commitments that cannot be currently satisfied, maintaining financial integrity and trust.

## Security and Risk Assessment

The method of using a large portion of the token's total supply or the entire wallet balance as the approval limit relies heavily on the security of the subscription canister. Given that the canister operates on an immutable smart contract model, where code once deployed cannot be altered arbitrarily, the risks associated with token mishandling are minimized. The high approval limit does not pose an increased risk because of the following reasons:

- **Blackholed Contract:** The propensity for the contract to execute only the code available prevents any malpractices regarding token handling.
- **Code Transparency:** Being open-sourced, the code underlying the subscription mechanism is available for audits and inspections by community members or security experts, fostering trust through transparency.

This approach not only enhances operational efficiency by reducing the frequency of user interactions for re-approvals but also aligns with best practices in blockchain management where trust is built into the codebase's security and transparency.

## Metadata

### icrc79_metadata

Returns all the metadata of the subscription canister in a single query.

The data model for metadata is based on the generic `Value` type which allows for encoding arbitrarily complex data for each metadata attribute. The metadata attributes are expressed as `(text, value)` pairs where the first element is the name of the metadata attribute and the second element the corresponding value expressed through the `Value` type.

Analogous to [ICRC-1 metadata](https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-1#metadata), metadata keys are arbitrary Unicode strings and must follow the pattern `<namespace>:<key>`, where `<namespace>` is a string not containing colons. The namespace `icrc7` is reserved for keys defined in the ICRC-7 standard.

The set of elements contained in a specific ledger's metadata depends on the ledger implementation, the list below establishes the currently defined fields.

The following metadata fields are defined by ICRC-7, starting with general collection-specific metadata fields:

The following are the more technical, implementation-oriented, metadata elements:

  * `icrc79:max_query_batch_size` of type `nat` (optional): The maximum batch size for batch query calls this implementation supports. When present, should be the same as the result of the [`icrc79_max_query_batch_size`](#icrc79_max_query_batch_size) query call.
  * `icrc79:max_update_batch_size` of type `nat` (optional): The maximum batch size for batch update calls this ledger implementation supports. When present, should be the same as the result of the [`icrc79_max_update_batch_size`](#icrc79_max_update_batch_size) query call.
  * `icrc79:default_take_value` of type `nat` (optional): The default value this ledger uses for the `take` pagination parameter which is used in some queries. When present, should be the same as the result of the [`icrc79_default_take_value`](#icrc79_default_take_value) query call.
  * `icrc79:max_take_value` of type `nat` (optional): The maximum `take` value for paginated query calls this ledger implementation supports. The value applies to all paginated queries the ledger exposes. When present, should be the same as the result of the [`icrc79_max_take_value`](#icrc79_max_take_value) query call.
  * `icrc79:max_memo_size` of type `nat` (optional): The maximum size of `memo`s as supported by an implementation. When present, should be the same as the result of the [`icrc79_max_memo_size`](#icrc79_max_memo_size) query call.
  * `icrc79:tx_window` of type `nat` (optional): The time window in seconds during which transactions can be deduplicated. Corresponds to the parameter `TX_WINDOW` as specified in the section on [transaction deduplication](#transaction_deduplication).
  * `icrc79:permitted_drift` of type `nat` (optional): The time duration in seconds by which the transaction deduplication window can be extended. Corresponds to the parameter `PERMITTED_DRIFT` as specified in the section on [transaction deduplication](#transaction_deduplication).

Note that if `icrc7_max...` limits specified through metadata are violated in a query call by providing larger argument lists or resulting in larger responses than permitted, the canister SHOULD return a response only to a prefix of the request items.

```candid "Type definitions" +=
// Generic value in accordance with ICRC-3
type Value = variant { 
    Blob : blob; 
    Text : text; 
    Nat : nat;
    Int : int;
    Array : vec Value; 
    Map : vec record { text; Value }; 
};
```

```candid "Methods" +=
icrc79_metadata : () -> (vec record { text; Value } ) query;
```

## Transaction Deduplication

The icrc79_subscribe functions should be subject to transaction deduplication as specified previously in [ICRC-7](https://github.com/dfinity/ICRC/blob/main/ICRCs/ICRC-7/ICRC-7.md#transaction-deduplication).

## Integrating ICRC-17 KYC Checks into Subscriptions


To ensure that subscribers meet KYC compliance standards as set by varying jurisdictions, and to provide a secure environment for both service providers and subscribers, the ICRC-79 standard incorporates an optional integration with the ICRC-17 KYC standard. This allows subscriptions to be linked with a designated ICRC-17 compliant KYC service canister.

#### ICRC-17 KYC Service Integration

For any subscription that requires KYC validation, the `SubscriptionRequest` can specify an `ICRC17Endpoint`, which is the principal of a KYC service canister adhering to the ICRC-17 standard. This inclusion enables automated KYC checks at subscription creation and potentially at recurring intervals, depending on the service requirement and regulatory guidelines.

#### Subscription Request with KYC

Below defines enhancements in the `SubscriptionRequest` data type to include the KYC endpoint, and describes the KYC validation process during the subscription set-up:

```candid
type SubscriptionRequest = record {
    ...
    ICRC17Endpoint: opt principal; // Optional KYC validation endpoint
    ...
};
```

#### KYC Validation Process

1. **Subscription Creation**: When a new subscription request is made (`icrc79_subscribe` call), and if the `ICRC17Endpoint` is provided, the subscription canister sends a KYC check request to the KYC canister using `icrc17_kyc_request` method.
   
2. **KYC Canister Request and Response**: The KYC canister processes the request and returns a `KYCResult`. Depending on the result (`Pass` or `Fail`), the subscription canister decides whether to proceed with subscription creation or not.
   
3. **Handling KYC Results**:
   - If `KYCResult.kyc` is `Pass`, the subscription process continues, setting up the subscription accordingly.
   - If `KYCResult.kyc` is `Fail` or requires further information (`NA`), the subscription request is rejected, and an appropriate error message is returned to the subscriber.