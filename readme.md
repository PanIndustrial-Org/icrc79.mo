Current Readme.md draft:

# ICRC-79.mo Subscription Service on DFINITY's Internet Computer

Pan Industrial's implementation of the ICRC-79 draft standard in motoko.

## Overview

ICRC-79 proposes Subscription Service allows you to manage periodic payment requests on the Internet Computer efficiently and securely. This implementation is open-source and designed to facilitate a wide array of subscription-based financial transactions, ensuring robustness and flexibility.

## Features

- **ICRC-2 Compliance**: Adheres to the ICRC-2 Approval and TransferFrom standard allowing any ICRC-2 token to be used for subscriptions.
- **ICRC-3 Compliance**: Adheres to the ICRC-3 transaction log specification. All subscriptions and state transitions can be recorded.
- **ICRC-79 Compliance**: Adheres to the Secure Subscription Canister Standard for secure and standardized subscriptions.
- **ICRC-80 Compliance**: Adheres to the ICRC-80 Multi-token canister endpoint and allows the payment of subscriptions in ICRC-80 tokens.
- **ICRC-72 Compliance**: (not yet implemented) Adheres to the Pub/Sub Standard for publishing subscription payments and subscription changes to your smart contract.
- **Dynamic Exchange Rates**: (non yet implemented)Integrates with the Exchange Rate Canister (XRC) for real-time currency conversion.
- **Flexible Intervals**: Supports various intervals like hourly, daily, weekly, monthly, yearly, and custom intervals.
- **Transaction Deduplication**: Prevents duplicate transactions ensuring reliable payment processes.
- **Rich Querying**: Comprehensive querying options to fetch subscription and payment details.

## Getting Started

### Mops

Please visit https://github.com/ZenVoich/mops for mops prerequisits

`mops add icrc79-mo`

```
import ICRC79 "mo:icrc79-mo";
import ICRC79Types "mo:icrc79-mo/migration/types";
import ICRC79Service "mo:icrc79-mo/Service";

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


private func getICRC79Environment<system>() : ICRC79.Environment {
  return {
    addLedgerTransaction = null; //todo: set up icrc3;
    canSendFee = null;
    tt = tt<system>();
    advanced = null;
  };
};

private func icrc79<system>() : ICRC79.ICRC79 {
  switch(_icrc79) {
    case(?icrc79) return icrc79;
    case(null) {
      let icrc79 = ICRC79.ICRC79(?icrc79MigrationState, Principal.fromActor(this), getICRC79Environment<system>() );
      _icrc79 := ?icrc79;
      return icrc79;
    };
  };  
};

```

## Usage

### Subscription Management Workflow

**Subscription Management on DFINITY's Internet Computer**

This document provides a comprehensive guide to managing subscriptions and payments using the **Internet Computer's** ICRC-79 canister standard. The workflow described herein is designed for developers planning to integrate subscription services into their web applications using the DFINITY agent.

### Workflow Overview

1. **Create a Subscription**
2. **Cancel a Subscription**
3. **Pause a Subscription**
4. **Fetch User Subscriptions**
5. **Fetch Payments**

#### 1. Create a Subscription

To create a subscription, your application will need to send a request to the `icrc79_subscribe` method. This method requires various parameters, such as the token canister principal, service canister principal, payment interval, and amount per interval.

**Parameters:**
- **Token Canister:** Principal of the token canister used for payments.
- **Service Canister:** Principal of the service canister.
- **Target Account:** Optional alternative destination for funds
- **Interval:** Frequency of payments (e.g., daily, monthly).
- **Amount per Interval:** Amount to be paid each interval.
- **Base Rate:** (Not yet implemented) Allows the subscription to use a base rate for determining the cost of a subscription at the of the charge. For example: Base Amount of 50, Base Rate of USD, Token Canister of ckBTC will result in a subscription payment of $50 worth of ckBTC.

Subscrption requests are an array of possible subscription items. Items should only show up once in the request.

**Request Structure:**
```motoko
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
      #ICRC17Endpoint: Principal; // Optional KYC validation endpoint
      #firstPayment: Nat; //Optional: set a time for the first regular payment.  If not set, the first payment will be immediate
      #nowPayment: Nat; //Optional. set a token amount to process immediately. requires firstPayment to be set and in the future
      #memo: Blob; //Optional: memo to include with the subscription
      #createdAtTime: Nat; //Optional: timestamp for deduplication
      #subaccount: Blob; //Optional: subaccount to use for the subscription
      #broker:Account; //Optional: broker to use for the subscription
  };
```

#### 2. Cancel a Subscription

To cancel an existing subscription, use the `icrc79_cancel_subscription` method. This method requires the subscription ID and an optional reason for the cancellation.

**Parameters:**
- **Subscription ID:** Unique identifier of the subscription.
- **Reason:** Optional reason for cancellation.

**Request Structure:**
```typescript
{
  subscriptionId: Nat,
  reason: Text // e.g., "User requested cancellation"
}
```

#### 3. Pause a Subscription

To pause a subscription, use the `icrc79_pause_subscription` method. This requires the subscription ID, the desired active state (false for pausing), and an optional reason.

**Parameters:**
- **Subscription ID:** Unique identifier of the subscription.
- **Active:** Boolean indicating whether to pause (false) or resume (true).
- **Reason:** Optional reason for pausing.

**Request Structure:**
```typescript
{
  subscriptionId: Nat,
  active: Bool, // e.g., false
  reason: Text // e.g., "User requested to pause"
}
```

#### 4. Fetch User Subscriptions

To retrieve a list of subscriptions associated with a user, use the `icrc79_get_user_subscriptions` method. This method supports optional filters for status, pagination, and other parameters.

**Parameters:**
- **Filter:** Optional filter criteria.
- **Prev:** Optional previous record for pagination.
- **Take:** Optional number of records to fetch.

**Request Structure:**
```typescript
{
  filter: ?{
    status: ?SubStatusFilter, 
    subscriptions: ?[Nat],
    subaccounts: ?[?Blob],
    products: ?[?Nat],
    services: ?[Principal]
  },
  prev: ?Nat, // Optional previous subscription ID for pagination
  take: ?Nat // Optional number of records to fetch
}
```

#### 5. Fetch Payments

To fetch a list of payments related to subscriptions, use the `icrc79_get_user_payments` method.

**Parameters:**
- **Filter:** Optional filters for payment retrieval.
- **Prev:** Optional previous record for pagination.
- **Take:** Optional number of records to fetch.

**Request Structure:**
```typescript
{
  filter: ?{
    status: ?SubStatusFilter, 
    subscriptions: ?[Nat],
    subaccounts: ?[?Blob],
    products: ?[?Nat],
    services: ?[Principal]
  },
  prev: ?Nat, // Optional previous payment ID for pagination
  take: ?Nat // Optional number of records to fetch
}
```

#### 5. Check status of next payment

Services may check the status of the next payment for a subscription using the `icrc79_confirm_subscription` endpoint. The item takes a vector of Confirm Requests. The check Rate, if provided will adjust the amount per interval by the associated amount in bps.  This can be used to adjust for volatility or a conversion rate.

**Parameters:**

```
  public type ConfirmRequests = {
    subscriptionId: Nat;
    checkRate: ?CheckRate;
  };

```

This function must be called by a canister and must include 10_000_000 cycles per individual request in the vector.

## Interceptors and Listeners

The ICRC-79 standard offers flexibility in customizing the behavior of various subscription-related processes through the use of interceptors and listeners. These are essentially hooks that allow you to intercept and modify the behavior or react to certain events occurring within the system. This functionality can be particularly useful for integrating additional business logic or for monitoring purposes.

### Interceptors

Interceptors in the context of ICRC-79 are functions that can be used to intercept specific actions within the subscription lifecycle, allowing you to include additional checks or modify the process flow. For example, you might want to add custom validations or modify subscription parameters dynamically.

#### Available Interceptors

1. **CanAddSubscription**: This interceptor allows you to influence the subscription request processing. You can include additional operation and top values, or modify subscription parameters before they are finalized.

   **Type Definition:**
   ```motoko
   public type CanAddSubscription = ?((SubscriptionState, Value, Value) -> Result.Result<(SubscriptionState, Value, Value), Service.SubscriptionError>);
   ```

### Listeners

Listeners are notification mechanisms triggered when certain events occur within the subscription process. These can be used to trigger additional actions such as logging, analytics, or integrations with other systems. They are methods that you register and which get called when certain events occur.

#### Available Listeners

1. **NewSubscriptionListener**: Triggered when a new subscription is created.
   ```motoko
   public type NewSubscriptionListener = <system>(SubscriptionState, trxId: Nat) -> ();
   ```

2. **ActivateSubscriptionListener**: Triggered when a subscription is activated.
   ```motoko
   public type ActivateSubscriptionListener = <system>(SubscriptionState, trxId: Nat) -> ();
   ```

3. **PauseSubscriptionListener**: Triggered when a subscription is paused.
   ```motoko
   public type PauseSubscriptionListener = <system>(SubscriptionState, trxId: Nat) -> ();
   ```

4. **CanceledSubscriptionListener**: Triggered when a subscription is canceled.
   ```motoko
   public type CanceledSubscriptionListener = <system>(SubscriptionState, trxId: Nat) -> ();
   ```

5. **NewPaymentListener**: Triggered when a new payment is made.
   ```motoko
   public type NewPaymentListener = <system>(SubscriptionState, PaymentRecord, trxId: Nat) -> ();
   ```

### Registering Listeners

To register a listener, you can use the corresponding method provided by the ICRC-79 library. Here’s an example of how to register a `NewSubscriptionListener`:

```motoko
import ICRC79 "mo:icrc79-mo";

// Define your listener function
actor class MyActor {
    public shared (msg) func handleNewSubscription(subscription: SubscriptionState, trxId: Nat) : async () {
        // Custom logic for handling new subscription
        Debug.print("New Subscription Created: " # Debug.show(subscription) # " Transaction ID: " # Debug.show(trxId));
    };
};

// Register the listener
let myActor = MyActor();
ICRC79.registerNewSubscriptionListener("myNamespace", myActor.handleNewSubscription);
```

### Example Usage in an Actor

Here’s an example of how you might set up both interceptors and listeners within a subscription management actor:

```motoko
import ICRC79 "mo:icrc79-mo";
import Principal "mo:base/Principal";

actor class MySubscriptionManager {
    public shared(msg) func icrc79_subscribe(req: ICRC79.SubscriptionRequest) : async ICRC79.SubscriptionResult {
        let customInterceptor: ICRC79.CanAddSubscription = ?func(subscriptionState: ICRC79.SubscriptionState, op: ICRC79.Value, top: ICRC79.Value) : async ICRC79.Service.Result<(ICRC79.SubscriptionState, ICRC79.Value, ICRC79.Value), ICRC79.Service.SubscriptionError> {
            // Additional custom checks or modifications
            switch(Map.get(discountList, Map.phash, subscriptionState.account.owner)){
              cae(null) return(subscriptionState, op, top);
              case(?val){
                let modifiedState = { subscriptionState with amountPerInterval = subscriptionState.amountPerInterval / 2 };
                let newOp = modifyOp(op, "amountPerInterval", #Nat(modifiedState.amountPerInterval));
                return #ok((modifiedState, newOp, top));
              };
            };
        };

        let myActor = MyActor();
        ICRC79.registerNewSubscriptionListener("myNamespace", myActor.handleNewSubscription);

        ICRC79.subscribe<System>(msg.callerPrincipal, req, customInterceptor);
    };
};

// Define the listener function
actor class MyActor {
    public shared(msg) func handleNewSubscription(subscription: ICRC79.SubscriptionState, trxId: Nat) : async () {
        // Custom logic for handling new subscription
        Debug.print("New Subscription Created: " # Debug.show(subscription) # " Transaction ID: " # Debug.show(trxId));
    };
};
```

By utilizing interceptors and listeners, you can effortlessly integrate custom logic and monitoring capabilities into your subscription management workflow, making it more adaptable to your specific needs.


## Integrating with Your Web Application

To integrate these functionalities into your web application, implement the DFINITY agent in your front-end code to make HTTP calls to the respective methods described above. Ensure all principal IDs, intervals, and other parameters are correctly assembled before making the API request.

By incorporating these defined processes, you'll efficiently manage subscriptions and payments on the Internet Computer, leveraging the robust features of ICRC-79. For further granularity and to understand all available parameters and their configurations, refer to the ICRC-79 standard documentation within the `ICRC-79.md` file.

### Notifying your app

Future implementations of this library will emit ICRC-72 events that your app will be able to listen for to respond to new subscriptions, payments, cancellations, etc.  Until this functionality has been released, you will need to pull information into your app by querying the `icrc79_get_service_subscriptions` and `icrc79_get_service_payments` end points, or by observing the ICRC-3 log produced by an ICRC-79 canister.

### Logs and Audit

The ICRC79-mo component takes an add_record parameter in it's environment. Wiring this up to the add_record function in a [ICRC3-mo](https://github.com/PanIndustrial-Org/icrc3.mo) class will enable a transaction log. Alternatively the developer can create a custom implementation.

## Extend and Contribute

We welcome contributions to enhance the service further. Follow these steps to contribute:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them with descriptive messages.
4. Push your changes.
5. Open a pull request.

## Methods Summary

Please refer to the [icrc-79 standard](icrc-79.md) for explanations of the functions and their parameters.  Generally there is a corresponding function in the library for each function in ICRC-79 with the addition of a caller parameter.

Refer to the main code for detailed candid type definitions and method signatures.

## Subscription Fees

The current implementation splits a subscription into two payments. 98.5% is delivered to the service canister indicated in the subscription, or optionally the target account, while 1.5% is delivered as a donation to the configured Public Goods account.contribute to education, scientific discovery, and the continued development of open source technology for the Internet Computer to account ifoh3-ksock-kdg2i-274hs-z3x7e-irgfv-eyqzv-esrlt-2qywt-jbocu-gae where is managed by ICDevs.org.

Fee payments can be overridden by implementing the canSendFee parameter on the environment parameter. This may be useful for manually tacking and excluding potential regulatory restrictions or censoring known-bad-actors.

```

  public type FeeDetail = {
    service: Principal;
    targetAccount: ?Account;
    subscribingAccount: Account;
    feeAccount: Account;
    token: (Principal,?Blob);
    feeAmount: Nat;
  };

  canSendFee: ?((FeeDetail) -> Bool);

  ```   

Future implementations will implement the ICRC-79 concept of a broker. For subscriptions containing a broker, an additional 1% will be removed from the main subscription amount and delivered to the broker account.

## Future Features

- Helper class for checking types and sizes of canister calls via inspect message
- Helper class for rate limiting to avoid ddos attacks
- ICRC-80 Compatibility
- ICRC-72 Compatibility
- Strategy for regulatory compliance
- Exchange rate functionality
- Safely retrieving token information

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## OVS Default Behavior

This motoko class has a default OVS behavior that sends cycles to the developer to provide funding for maintenance and continued development. In accordance with the OVS specification and ICRC85, this behavior may be overridden by another OVS sharing heuristic or turned off. We encourage all users to implement some form of OVS sharing as it helps us provide quality software and support to the community.

Default behavior: 1 XDR per 100 payments processed;

Default Beneficiary: Pan Industrial