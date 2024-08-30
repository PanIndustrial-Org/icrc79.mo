import D "mo:base/Debug";
import Text "mo:base/Text";
import Principal "mo:base/Principal";

import Service "../Service";
import ICRC79 "../";
import ICRC79MigrationTypes "../migrations/types";
import ICRC79Migrations "../migrations";
import TT "mo:timer-tool";
import KnownTokens "../knownTokens";


shared (deployer) actor class Subs(initArgs: ?{
  icrc79InitArgs: ?ICRC79MigrationTypes.Args;
  ttInitArgs : ?TT.Args;
}) : async Service.Service = this {

  let debug_channel = {
    announce = true;
  };

  let ttDefaultArgs = null;


  stable var icrc79MigrationState : ICRC79MigrationTypes.State = #v0_0_0(#data);
  stable var ttMigrationState : TT.State = #v0_0_0(#data);

  icrc79MigrationState := ICRC79Migrations.migrate(
    icrc79MigrationState, 
    #v0_1_0(#id), 
    switch(do?{initArgs!.icrc79InitArgs!}){
      case(null) {
        ?{
          publicGoodsAccount = ?{owner = Principal.fromText("ifoh3-ksock-kdg2i-274hs-z3x7e-irgfv-eyqzv-esrlt-2qywt-jbocu-gae"); subaccount = null;};
          nextSubscriptionId = null;
          nextPaymentId = null;
          nextNotificationId = null;
          existingSubscriptions = [];
          defaultTake = null;
          feeBPS = null;
          maxUpdates = null;
          maxQueries = null;
          maxTake = null;
          trxWindow = null;
          minDrift = null;
          maxMemoSize = null;
          tokenInfo = ?KnownTokens.knownTokens();
        };
      };
      case(?val) val;
    }, 
    deployer.caller);

  ttMigrationState :=  TT.init(TT.initialState(),#v0_1_0(#id), switch(do?{initArgs!.ttInitArgs!}){
      case(null) null;
      case(?val) val;
    }, deployer.caller);

  let #v0_1_0(#data(currentICRC79State)) = icrc79MigrationState;
  let #v0_1_0(#data(currentTTState)) = ttMigrationState;

  private var _icrc79 : ?ICRC79.ICRC79 = null;

  private func getICRC79Environment<system>() : ICRC79.Environment {
    return {
      add_ledger_transaction = null; //todo: set up icrc3;
      canSendFee = ?blockCharlie;
      tt = tt<system>();
      advanced = null;
    };
  };

  private func blockCharlie(fromAccount: ICRC79.Account, toAccount: ICRC79.Account, canister: Principal, fee: Nat) : Bool {
    
    debug if(debug_channel.announce) D.print("Subs: blockCharlie" # debug_show(fromAccount) # debug_show(toAccount) # debug_show(canister) # debug_show(fee));
    if(fromAccount.owner == Principal.fromText("dnpjs-7k32s-jd4uz-xqxaq-qgg7q-nfkuq-xwqfx-t7yfg-7ezxh-si2a4-kqe")){ // Charlie from pic.js
      return false;
    };
    return true;
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

  func q_icrc79() : ICRC79.ICRC79 {
   let ?found = _icrc79 else D.trap("ICRC79 not initialized");
   found;
  };

  private var _tt : ?TT.TimerTool = null;

  private func getTTEnvironment() : TT.Environment {
    return {
      advanced = null;
      synUnsafe = null;
      reportExecution = null;
      reportError = null;
      syncUnsafe = null;
      reportBatch = null;
    };
  };

  private func tt<system>() : TT.TimerTool {
    switch(_tt) {
      case(?tt) return tt;
      case(null) {
        let x = TT.TimerTool(?ttMigrationState, Principal.fromActor(this), getTTEnvironment());
        x.initialize<system>();
        _tt := ?x;
        x;
      };
    };  
  };

  public shared ({ caller }) func hello_world() : async Text {
    return "Hello World!";
  };

  public shared(msg) func icrc79_subscribe(req: Service.SubscriptionRequest) : async Service.SubscriptionResult {

    D.print("Subs: icrc79_subscribe" # debug_show(req));

    let result = await* icrc79<system>().subscribe<system>(msg.caller, req : Service.SubscriptionRequest, null);
    result;

  };

    public shared(msg) func icrc79_cancel_subscription(req: [{ subscriptionId: Nat; reason: Text }]) : async [Service.CancelResult] {
        // Implementation of cancel subscription logic
        let result = await* icrc79<system>().cancel_subscription<system>(msg.caller, req);
        result;
    };

    public shared(msg) func icrc79_confirm_subscription(confirmRequests: [ICRC79.ConfirmRequests]) : async [Service.ConfirmResult] {
        let result = await* icrc79<system>().checkAllowanceForSubscription<system>(msg.caller, confirmRequests);
        result;
    };

    public shared(msg) func icrc79_pause_subscription(req: ICRC79.PauseRequest) : async [Service.PauseResult] {
        debug if(debug_channel.announce) D.print("Subs: icrc79_pause_subscription" # debug_show(req));
        let result = await* icrc79<system>().pause_subscription<system>(msg.caller, req);

        result;
    };

    public query(msg) func icrc79_get_user_subscriptions(filter: ?ICRC79.UserSubscriptionsFilter, prev: ?Nat, take: ?Nat) : async [Service.Subscription] {
        // Implementation of get user subscriptions logic
        let result = q_icrc79().get_user_subscriptions(msg.caller, filter, prev, take);
        result;
    };

    public query func icrc79_get_service_subscriptions(service: Principal, filter: ?Service.ServiceSubscriptionFilter, prev: ?Nat, take: ?Nat) : async [Service.Subscription] {
        // Implementation of get service subscriptions logic
        let result = q_icrc79().get_sevice_subscriptions(service, filter, prev, take);
        result;
    };

    public query(msg) func icrc79_get_user_payments(filter: ?ICRC79.UserSubscriptionsFilter, prev: ?Nat, take: ?Nat) : async [Service.PaymentRecord] {
        // Implementation of get user payments logic
        debug if(debug_channel.announce) D.print("Subs: icrc79_get_user_payments" # debug_show(filter) # debug_show(prev) # debug_show(take));
        q_icrc79().get_user_payments(msg.caller, filter, prev, take);
    };

    public query(msg) func icrc79_get_payments_pending(subscriptionIds: [Nat]) : async [?Service.PendingPayment] {
        // Implementation of get user pending payments logic
        debug if(debug_channel.announce) D.print("Subs:     public query func icrc79_payments_pending(subscriptionIds: [Nat]) : async [Service.PendingPayment] {" # debug_show(subscriptionIds));
        q_icrc79().get_payments_pending(msg.caller, subscriptionIds);
    };

    public query func icrc79_get_service_payments(service: Principal, filter:?ICRC79.ServiceSubscriptionFilter, prev: ?Nat, take: ?Nat) : async [Service.PaymentRecord] {
        // Implementation of get service payments logic
         let result = q_icrc79().get_sevice_payments(service, filter, prev, take);
        result;
    };



    public query(msg) func icrc79_get_service_notifications(service: Principal, prev: ?Nat, take: ?Nat) : async [Service.ServiceNotification] {
        // Implementation of get service notifications logic
        let result = q_icrc79().get_service_notifications(msg.caller, service, prev, take);
        result;
    };

    public query func icrc79_metadata() : async [(Text, Service.Value)] {
        // Implementation of metadata retrieval logic
        [
          ("icrc79:max_query_batch_size", #Nat(q_icrc79().get_state().maxQueries)),
          ("icrc79:max_update_batch_size", #Nat(q_icrc79().get_state().maxUpdates)),
          ("icrc79:default_take_value", #Nat(q_icrc79().get_state().defaultTake)),
          ("icrc79:max_take_value", #Nat(q_icrc79().get_state().maxTake)),
          ("icrc79:max_memo_size", #Nat(q_icrc79().get_state().maxMemoSize)),
          ("icrc79:tx_window", #Nat(q_icrc79().get_state().trxWindow)),
          ("icrc79:permitted_drift", #Nat(q_icrc79().get_state().minDrift)),
        ];
    };

    public query func icrc79_max_query_batch_size() : async Nat {
        // Implementation of max query batch size logic
        q_icrc79().get_state().maxQueries;
    };

    public query func icrc79_max_update_batch_size() : async Nat {
        // Implementation of max update batch size logic
        q_icrc79().get_state().maxUpdates;
    };

    public query func icrc79_default_take_value() : async Nat {
        // Implementation of default take value logic
        q_icrc79().get_state().defaultTake;
    };

    public query func icrc79_max_take_value() : async Nat {
        // Implementation of max take value logic
        q_icrc79().get_state().maxTake;
    };

    public query func icrc79_max_memo_size() : async Nat {
        // Implementation of max memo size logic
        q_icrc79().get_state().maxMemoSize;
    };

    public query func icrc79_tx_window() : async Nat {
        // Implementation of tx window logic
        q_icrc79().get_state().trxWindow; // 24 hours
    };

    public query func icrc79_permitted_drift() : async Nat {
        // Implementation of permitted drift logic
        q_icrc79().get_state().minDrift;//  1 minute
    };

    ///MARK: Admin Functions
    public shared(msg) func add_token(tokenCanister: Principal, tokenPointer: ?Blob) : async ?ICRC79.TokenInfo {
        // Implementation of add token logic
        await* icrc79<system>().addTokenInfo(tokenCanister, tokenPointer);
    };

};