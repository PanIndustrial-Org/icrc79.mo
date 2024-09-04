import Migration "./migrations";
import MigrationTypes "./migrations/types";
import Service "Service";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import Error "mo:base/Error";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Array "mo:base/Array";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Star "mo:star/star";
import Sha256 "mo:sha2/Sha256";
import Conversion "mo:candy/conversion";
import ovsFixed "mo:ovs-fixed";
import RepIndy "mo:rep-indy-hash";
import Serializer "serializer";

module {

  /// Used to control debug printing for various actions.
  let debug_channel = {
    announce = true;
    pause = true;
    subscribe = true;
    unreachable = true;
    cycles = true;
  };

  /// Exposes types from the migrations library to users of this module, allowing them to utilize these types in interacting 
  /// with instances of ICRC1 tokens and their respective attributes and actions.
  public type State =                           MigrationTypes.State;

  // Imports from types to make code more readable
  public type CurrentState =                    MigrationTypes.Current.State;
  public type Environment =                     MigrationTypes.Current.Environment;

  public type Account =                         MigrationTypes.Current.Account;
  public type SubscriptionState =               MigrationTypes.Current.SubscriptionState;
  public type SubscriptionStateShared =         MigrationTypes.Current.SubscriptionStateShared;
  public type TokenInfo =                       MigrationTypes.Current.TokenInfo;
  public type SubStatus =                       MigrationTypes.Current.SubStatus;
  public type Value =                           MigrationTypes.Current.Value;
  public type ProductSubscriptionMap =          MigrationTypes.Current.ProductSubscriptionMap;
  public type ServiceSubscriptionMap =          MigrationTypes.Current.ServiceSubscriptionMap;
  public type SubAccountSubscriptionMap =       MigrationTypes.Current.SubAccountSubscriptionMap;
  public type UserSubscriptionIndex =           MigrationTypes.Current.UserSubscriptionIndex;
  public type CanAddSubscription =              MigrationTypes.Current.CanAddSubscription;
  public type ScheduledPaymentArgs =            MigrationTypes.Current.ScheduledPaymentArgs;
  public type ServiceNotificationType =         MigrationTypes.Current.ServiceNotificationType;
  public type ServiceNotification =             MigrationTypes.Current.ServiceNotification;
  public type PaymentRecord =                   MigrationTypes.Current.PaymentRecord;
  public type ExchangeRate =                    MigrationTypes.Current.ExchangeRate;
  public type ExchangeRateMetadata =            MigrationTypes.Current.ExchangeRateMetadata;
  public type Asset =                           MigrationTypes.Current.Asset;
  public type NewSubscriptionListener =         MigrationTypes.Current.NewSubscriptionListener;
  public type CanceledSubscriptionListener=     MigrationTypes.Current.CanceledSubscriptionListener;
  public type NewPaymentListener =              MigrationTypes.Current.NewPaymentListener;
  public type ActivateSubscriptionListener =    MigrationTypes.Current.ActivateSubscriptionListener;
  public type PauseSubscriptionListener =       MigrationTypes.Current.PauseSubscriptionListener;
  public type FeeDetail =                      MigrationTypes.Current.FeeDetail;
  


  public let ktHash =                           MigrationTypes.Current.ktHash;
  public let nullNHash =                        MigrationTypes.Current.nullNHash;
  public let nullSubaccount =                   MigrationTypes.Current.nullSubaccount;
  public let TT =                               MigrationTypes.Current.TimerTool;
  public let isICRC80 =                         MigrationTypes.Current.isICRC80;
  public let subAccountEqual =                  MigrationTypes.Current.subAccountEqual;
  public let shareSubscriptionState =           MigrationTypes.Current.shareSubscriptionState;


  public type SubscriptionRequest =             Service.SubscriptionRequest;
  public type SubscriptionRequestItem =         Service.SubscriptionRequestItem;
  public type SubscriptionResponse =            Service.SubscriptionResponse;
  public type SubscriptionResult =              Service.SubscriptionResult;
  public type SubscriptionResultItem =          Service.SubscriptionResultItem;
  public type Interval =                        Service.Interval;
  public type ICRC10Actor =                     Service.ICRC10Actor;
  public type ICRC2Actor =                      Service.ICRC2Actor;
  public type ICRC80Actor =                     Service.ICRC80Actor;
  public type TokenPointer =                    Service.TokenPointer;
  public type UserSubscriptionsFilter =         Service.UserSubscriptionsFilter;
  public type CancelResult =                    Service.CancelResult;
  public type PauseRequest =                    Service.PauseRequest;
  public type PauseResult =                     Service.PauseResult;
  public type SubStatusFilter =                 Service.SubStatusFilter;
  public type Subscription =                    Service.Subscription;
  public type ServiceSubscriptionFilter =       Service.ServiceSubscriptionFilter;
  public type PendingPayment =                  Service.PendingPayment;
  public type ConfirmRequests =                 Service.ConfirmRequests;
  public type ConfirmResult =                   Service.ConfirmResult;
  public type CheckRate =                       Service.CheckRate;

  

  public func initialState() : State {#v0_0_0(#data)};
  public let currentStateVersion = #v0_1_0(#id);

  public let init = Migration.migrate;

  //convienence variables to make code more readable
  public let Map = MigrationTypes.Current.Map;
  public let Set = MigrationTypes.Current.Set;
  public let Vector = MigrationTypes.Current.Vector;

  public let ONE_MINUTE = 60_000_000_000;

  public class ICRC79(stored: ?State, canister: Principal, environment: Environment){

    var state : CurrentState = switch(stored){
      case(null) {
        let #v0_1_0(#data(foundState)) = init(initialState(),currentStateVersion, null, canister);
        foundState;
      };
      case(?val) {
        let #v0_1_0(#data(foundState)) = init(val,currentStateVersion, null, canister);
        foundState;
      };
    };

    var transactionTicker = 0; //used to make sure that transactions are unique

    public func getState() : CurrentState {
      return state;
    };

    public func getEnvironment() : Environment {
      return environment;
    };

    public func natnow() : Nat {
      Int.abs(Time.now());
    };

    public func nat64now() : Nat64 {
      Nat64.fromNat(natnow());
    };

    private func parseSubscriptionRequest(caller: Principal, request: [SubscriptionRequestItem]) : SubscriptionStateShared {

      if(Principal.isAnonymous(caller)) D.trap("Anon not allowed");

      var tokenCanister : ?Principal = null;
      var tokenPointer : ?TokenPointer = null;
      var serviceCanister : ?Principal = null;
      var interval : ?Interval = null;
      var amountPerInterval : ?Nat = null;
      var baseRateAsset : ?Asset = null;
      var endDate : ?Nat = null;
      var targetAccount : ?Account = null;
      var productId : ?Nat = null;
      var ICRC17Endpoint : ?Principal = null;
      var firstPayment : ?Nat = null;
      var nowPayment : ?Nat = null;
      var memo : ?Blob = null;
      var createdAtTime : ?Nat = null;
      var subaccount : ?Blob = null;
      var checkRate : ?CheckRate = null;
      var brokerId : ?Principal = null;

      for(thisItem in request.vals()){
        switch(thisItem){
          case (#tokenCanister(val)) {
            tokenCanister := ?val;
          };
          case (#tokenPointer(val)) {
            tokenPointer := ?val;
          };
          case(#broker(val)){
            brokerId := ?val; 
          };
          case (#serviceCanister(val)) {
            serviceCanister := ?val;
          };
          case (#interval(val)) {
            interval := ?val;
          };
          case (#amountPerInterval(val)) {
            amountPerInterval := ?val;
          };
          case (#baseRateAsset(val)) {
            baseRateAsset := ?val.0;
            checkRate := ?val.1;
          };
          case (#endDate(val)) {
            endDate := ?val;
          };
          case (#targetAccount(val)) {
            switch(val.subaccount){
              case(null) {};
              case(?val) {
                if(val.size() > 32){
                  D.trap("target subaccount too long");
                };
              };
            };
            
            targetAccount := ?val;
          };
          case (#productId(val)) {
            productId := ?val;
          };
          case (#ICRC17Endpoint(val)) {
            ICRC17Endpoint := ?val;
          };
          case (#firstPayment(val)) {
            firstPayment := ?val;
          };
          case (#nowPayment(val)) {
            nowPayment := ?val;
          };
          case (#memo(val)) {
            if(val.size() > 32){
              D.trap("memo too long");
            };
            memo := ?val;
          };
          case (#createdAtTime(val)) {
            createdAtTime := ?val;
          };
          case (#subaccount(val)) {
            if(val.size() > 32){
              D.trap("subaccount long");
            };
            subaccount := ?val;
          };
          case(#brokerId(val)){
            brokerId := ?val; 
          };
        };
      };
      
      return {
        tokenCanister = switch(tokenCanister){
          case(null) D.trap("no token canister provided");
          case(?val) val;
        };
        tokenPointer = tokenPointer;
        serviceCanister = switch(serviceCanister){
          case(null) D.trap("no service canister provided");
          case(?val) val;
        };
        brokerId = brokerId;
        interval = switch(interval){
          case(null) D.trap("no interval provided");
          case(?val) val;
        };
        amountPerInterval = switch(amountPerInterval){
          case(null) D.trap("no amount per interval provided");
          case(?val) val;
        };
        baseRateAsset = baseRateAsset;
        endDate = endDate;
        targetAccount = switch(targetAccount){
          case(null) null;
          case(?targetAccount) ?targetAccount;
        };
        productId = productId;
        ICRC17Endpoint = ICRC17Endpoint;
        firstPayment = firstPayment;
        nowPayment = nowPayment;
        memo = memo;
        createdAtTime = createdAtTime;
        checkRate = checkRate;
        account = {
          owner = caller;
          subaccount = subaccount;
        };
        nextPayment = switch(firstPayment){
          case(null) {
            ?natnow();
          };
          case(?val) {
            if( val <= natnow()){
              ?natnow();
            } else {
              debug logDebug(debug_channel.announce, "Subs: parseSubscriptionRequest setting firstPayment" # debug_show((val, natnow())));
              ?val;
            };
          };
        };
        nextPaymentAmount = switch(nowPayment){
          case(null){
            amountPerInterval;
          };
          case(?val) ?val;
        };
        nextTimerId = null;
        status = #Active;
        subscriptionId = 0;
        history = [];
      };
    };

    private func haveTokenInfo(principal: Principal, tokenPointer: ?Blob) : ?TokenInfo {
      let ?tokenInfo = Map.get(state.tokenInfo, ktHash, (principal, tokenPointer)) else return null;
      return ?tokenInfo;
    };

    public func addTokenInfo(principal: Principal, tokenPointer: ?Blob) : async* ?TokenInfo {
      switch(await* getTokenInfo(principal, tokenPointer)){
        case(null) {
          return null;
        };
        case(?val){
          ignore Map.put(state.tokenInfo, ktHash, (principal, tokenPointer), val);
          debug logDebug(debug_channel.announce, "Subs: addTokenInfo" # debug_show((val, Map.toArray(state.tokenInfo))));
          return ?val;
        };
      };
    };

    private func logDebug(bEmit: Bool, message: Text) {
      if(bEmit) D.print(message);
    };

    private func getTokenInfo(principal: Principal, tokenPointer: ?Blob) : async* ?TokenInfo {
      debug logDebug(debug_channel.announce, "Subs: getTokenInfo announce" # debug_show((principal, tokenPointer)));

      ///check that the canister is on the approved tokens list
      let canister : ICRC10Actor = actor(Principal.toText(principal));
      let standards = try {
        await canister.icrc10_supported_standards();
      } catch (error) {
        debug logDebug(debug_channel.announce, "Subs: getTokenInfo err" # Error.message(error));

        try {
          debug logDebug(debug_channel.announce, "Subs: getTokenInfo try icrc1");
          
          let result = await canister.icrc1_supported_standards();
          debug logDebug(debug_channel.announce, "Subs: getTokenInfo result" # debug_show(result));
          result;
        } catch (error) {
          debug logDebug(debug_channel.announce, "Subs: getTokenInfo err2" # Error.message(error));
          return null;
        };
      };

      debug logDebug(debug_channel.announce, "Subs: getTokenInfo standards" # debug_show(standards));

      let standardResult = Vector.new<Text>();

      var b80 = false;

      for(thisItem in standards.vals()){
        let lower = Text.toLowercase(thisItem.name);
        if(lower == "icrc-2"){
          Vector.add(standardResult, "icrc2");
        };
        if(lower == "icrc-80"){
          b80 := true;
          Vector.add(standardResult, "icrc80");
        };
      };

      debug logDebug(debug_channel.announce, "Subs: getTokenInfo standard" # debug_show(standardResult));

      let tokenInfo = if(b80 == false){
        //get icrc1 metadata
        let icrc1canister : ICRC2Actor = actor(Principal.toText(principal));
        try {
          let fee = icrc1canister.icrc1_fee();
          let symbol = icrc1canister.icrc1_symbol();
          let decimal = icrc1canister.icrc1_decimals();
          let totalSupply = icrc1canister.icrc1_total_supply();
          switch(await fee, await symbol, await decimal, await totalSupply){
            case (fee, symbol, decimal, totalSupply){
              {
                tokenFee = ?fee;
                tokenSymbol = symbol;
                tokenDecimals = decimal;
                tokenTotalSupply = totalSupply;
                tokenPointer = null;
                standards = Vector.toArray(standardResult);
                tokenCanister = principal;
              }: TokenInfo;
            };
          };
        } catch (error) {
          debug logDebug(debug_channel.announce, "Subs: getTokenInfo err" # Error.message(error));
          return null;
        };
      } else {
        //get icrc80 metadata
        let icrc80canister : ICRC80Actor = actor(Principal.toText(principal));
        let ?tokenPointerParsed = tokenPointer else return null;
        try {
          let fee = icrc80canister.icrc80_fee_by_id(tokenPointerParsed);
          let symbol = icrc80canister.icrc80_symbol_by_id(tokenPointerParsed);
          let decimal = icrc80canister.icrc80_decimals_by_id(tokenPointerParsed);
          let totalSupply = icrc80canister.icrc80_total_supply_by_id(tokenPointerParsed);
          switch(await fee, await symbol, await decimal, await totalSupply){
            case (fee, symbol, decimal, totalSupply){
              {
                tokenFee = ?fee;
                tokenSymbol = symbol;
                tokenDecimals = decimal;
                tokenTotalSupply = totalSupply;
                tokenPointer = null;
                standards = Vector.toArray(standardResult);
                tokenCanister = principal;
              }: TokenInfo;
            };
          };
        } catch (error) {
          debug logDebug(debug_channel.announce, "Subs: getTokenInfo err" # Error.message(error));
          return null;
        };
      };

      return ?tokenInfo;
    };

    public func addRecord<system>(op: Value, top: ?Value) : Nat{
      switch(environment.addLedgerTransaction){
        case(null) 0; //todo : should we throw an error?
        case(?val) val<system>(op, top);
      };
    };

    public func checkAllowanceForSubscription<system>(caller: Principal, confirmRequests: [ConfirmRequests]) : async* [ConfirmResult] {

      let available = ExperimentalCycles.available();

      if(available < 500_000 * confirmRequests.size()){
        D.trap("Subs: checkAllowanceForSubscription not enough cycles available");
      };
      
      var allocated = 0;
      var xnet = 0;
      var refunded = 0;

      let results = Buffer.Buffer<ConfirmResult>(confirmRequests.size());

      label proc for(thisSub in confirmRequests.vals()){

        let ?subscription = Map.get(state.subscriptions, Map.nhash, thisSub.subscriptionId) else {
          results.add(?#Err(#SubscriptionNotFound));
          continue proc;
        };

        let ?tokenInfo = Map.get(state.tokenInfo, ktHash, (subscription.tokenCanister, subscription.tokenPointer)) else {
            results.add(?#Err(#TokenNotFound));
            continue proc;
        };

        xnet += 500_000;

        // Validate allowance - must be enough for at least the first interval
        // todo: also check the first payment pathway
        let requiredAmountBase = subscription.amountPerInterval + ( 2 * (switch(tokenInfo.tokenFee){
          
          case(null) 10000;
          case(?val) val;
        }));

        let requiredAmount = switch(thisSub.checkRate){
          case(null) requiredAmountBase;
          case(?val) (requiredAmountBase * Nat64.toNat(val.rate))/ Nat32.toNat(val.decimals);
        };

        let allowanceResult = try{
          await* checkAllowance(subscription.tokenCanister, subscription.account, {owner = canister; subaccount = null;}, requiredAmount);
        } catch (error) {
          results.add(?#Err(#Other({message = Error.message(error); code = 1;})));
          continue proc;
        };

        debug logDebug(debug_channel.subscribe,"Subs: allowanceResult" # debug_show(allowanceResult));

        switch (allowanceResult) {
            case (#err(err)){
              results.add(?#Err(#InsufficientAllowance(err)));
              continue proc;
            };
            case (#ok){
              results.add(?#Ok(subscription.subscriptionId));
            };
                // Proceed with subscription creation
        };
      };

      if(xnet < available){
        ignore ExperimentalCycles.accept<system>(xnet);
      } else {
        ignore ExperimentalCycles.accept<system>(available);
      };

      return Buffer.toArray(results);
    };

    
    ///MARK: Subscribe
    public func subscribe<system>(caller: Principal, request: SubscriptionRequest, canAddSubscription: CanAddSubscription) : async* SubscriptionResult {

      debug logDebug(debug_channel.announce, "Subs: subscribe" # debug_show(request));

      let results = Buffer.Buffer<SubscriptionResultItem>(1);
      let parsedItems = Buffer.Buffer<SubscriptionStateShared>(1);
      let now = natnow();

      //add items for dedup
      label preproc for(thisRequest in request.vals()){
        let parsedRequest = parseSubscriptionRequest(caller, thisRequest);
        parsedItems.add(parsedRequest);

        let (preop, pretop) = Serializer.serializeSubRequest(parsedRequest, caller, now);

          //check for duplicate
        let trxhash = Blob.fromArray(RepIndy.hash_val(preop));

        debug logDebug(debug_channel.subscribe,"Subs: trxhash" # debug_show(trxhash));

        switch (Map.get(state.recentTrx, Map.bhash, trxhash)) {
          case (?found) {
            debug logDebug(debug_channel.subscribe,"Subs: found" # debug_show(found));
            //fail the whole batch
            if(found + state.minDrift + state.trxWindow > now){
              debug logDebug(debug_channel.subscribe,"Subs: found too recent " # debug_show(found));
              return([?#Err(#Duplicate)]);
            };
          };
          case (null) {};
        };

        ignore Map.putMove<Blob,Nat>(state.recentTrx, Map.bhash, trxhash, ?natnow());
      };

      label proc for(parsedRequest in parsedItems.vals()){

      //validate the subscription
     

      //check
        let existingSubscriptions = do? {
          let subAccountMap = Map.get(state.userSubscriptionIndex, Map.phash, parsedRequest.account.owner);
          let subBlob = subaccountToBlob(parsedRequest.account.subaccount);
          let serviceMap = Map.get(subAccountMap!, Map.bhash, subBlob);
          let productSubMap = Map.get(serviceMap!, Map.phash, parsedRequest.serviceCanister);
          let productMap = Map.get(productSubMap!, nullNHash, parsedRequest.productId);
          productMap!;
        };

        switch(existingSubscriptions){
          case(null) {};
          case(?val){
            label search for(thisSub in Set.keys(val)){
              let ?thisSubDetail = Map.get(state.subscriptions, Map.nhash, thisSub) else continue search;
              if(thisSubDetail.status == #Active){
                results.add(?#Err(#FoundActiveSubscription(thisSub)));
                continue proc;
              };
            };
          };
        };

        // Get token info
        debug logDebug(debug_channel.subscribe,"Subs: parsedRequest" # debug_show(parsedRequest));

        if(parsedRequest.account.owner != caller){
          results.add(?#Err(#Unauthorized));
          continue proc;
        };

         //if interval make sure it isn't less than 1 hour.
        switch(parsedRequest.interval){
          case(#Interval(val)){
            if(val < 3_600_000_000_000){
              results.add(?#Err(#InvalidInterval));
              continue proc;
            };
          };
          case(_) {};
        };

        switch(parsedRequest.endDate){
          case(?val){
            if(val < natnow()){
              results.add(?#Err(#InvalidDate));
              continue proc;
            };
          };
          case(null){};
        };

        let ?tokenInfo = switch(Map.get(state.tokenInfo, ktHash, (parsedRequest.tokenCanister, parsedRequest.tokenPointer))){
          case(null) {
            ///temp: only allow hard coded tokens
            results.add(?#Err(#TokenNotFound));
            continue proc;

            //future code
            switch(await* getTokenInfo(parsedRequest.tokenCanister, parsedRequest.tokenPointer)){
              case(null) null;
              case(?val) {
                ignore Map.put(state.tokenInfo, ktHash, (parsedRequest.tokenCanister, parsedRequest.tokenPointer), val);
                ?val;
              };
            };
          };
          case(?val) ?val;
        }  else {
          results.add(?#Err(#TokenNotFound));
          continue proc;
        };

        debug logDebug(debug_channel.subscribe, "Subs: tokenInfo" # debug_show(tokenInfo));

        let totalSupply = tokenInfo.tokenTotalSupply;
        let fee = switch(tokenInfo.tokenFee){
          case(null) 10000;
          case(?val) val;
        };

        // Calculate max allowance needed
        let maxAllowance = calculateMaxAllowance(parsedRequest, tokenInfo.tokenTotalSupply, fee);

        let requiredAmountBase = parsedRequest.amountPerInterval + ( 2 * (switch(tokenInfo.tokenFee){
          case(null) 10000;
          case(?val) val;
        }));

        let requiredAmount = switch(parsedRequest.checkRate){
          case(null) requiredAmountBase;
          case(?val) (requiredAmountBase * Nat64.toNat(val.rate))/ Nat32.toNat(val.decimals);
        };

        debug logDebug(debug_channel.subscribe, "Subs: maxAllowance" # debug_show(maxAllowance));

        // Validate allowance - must be enough for at least the first interval
        // todo: also check the first payment pathway
        let allowanceResult = await* checkAllowance(parsedRequest.tokenCanister, parsedRequest.account, {owner = canister; subaccount = null;}, parsedRequest.amountPerInterval + ( 2 * (switch(tokenInfo.tokenFee){
          case(null) 10000;
          case(?val) val;
        })));

        debug logDebug(debug_channel.subscribe, "Subs: allowanceResult" # debug_show(allowanceResult));

        switch (allowanceResult) {
            case (#err(err)){
              
              results.add(?#Err(#InsufficientAllowance(err)));
              continue proc;
            };
            case (#ok){};
                // Proceed with subscription creation
        };

        // Create the subscription
        let subscriptionId = state.nextSubscriptionId;

        let newSubscription : SubscriptionState = {
            tokenPointer = parsedRequest.tokenPointer;
            subscriptionId = subscriptionId;
            tokenCanister = parsedRequest.tokenCanister;
            serviceCanister = parsedRequest.serviceCanister;
            Interval = parsedRequest.interval;
            productId = parsedRequest.productId;
            brokerId = parsedRequest.brokerId;
            amountPerInterval = parsedRequest.amountPerInterval;
            baseRateAsset = parsedRequest.baseRateAsset;
            endDate = parsedRequest.endDate;
            targetAccount = parsedRequest.targetAccount;
            ICRC17Endpoint = parsedRequest.ICRC17Endpoint; 
            account =  parsedRequest.account;
            interval = parsedRequest.interval;
            var nextPayment = parsedRequest.nextPayment;
            var nextPaymentAmount = parsedRequest.nextPaymentAmount;
            var nextTimerId = null;
            var status = #Active;
            history = Vector.new<Nat>(); 
        };

        let (op,top) = Serializer.serializeSubCreate(newSubscription, caller, natnow());

        let (finalSub, finalOp, finalTop) = switch(canAddSubscription){
          case(?val){
            switch(val(newSubscription, op, top)){
              case(#ok(val)){
                (val.0, val.1, val.2);
              };
              case(#err(err)){
                results.add(?#Err(err));
                continue proc;
              };
            };
        };
          case(null) {
            (newSubscription, op, top);
          };
        };

        fileSubscription(finalSub);
        state.nextSubscriptionId += 1;

        //schedule the first payment
        switch(finalSub.nextPayment, finalSub.nextPaymentAmount){
          case(?valDate, ?valAmount){
            debug logDebug(debug_channel.announce, "Subs: subscribe scheduling firstPayent" # debug_show((valDate, valAmount)));
            finalSub.nextTimerId := ?environment.tt.setActionASync<system>(valDate, {
              actionType = "subscriptionPayment";
              params = to_candid({
                subscriptionId = finalSub.subscriptionId;
                amountAtSet = valAmount;
                timeAtSet = valDate;
                retries = 0;
              });
            }, ONE_MINUTE * 5);
          };
          case(_, _){
            debug logDebug(debug_channel.unreachable, "unreachable code reached, nextpayment was not set" # debug_show((finalSub.nextPayment, finalSub.nextPaymentAmount)));
          };
        };
        

        let trxId = addRecord<system>(finalOp, ?finalTop);

        //notify listeners of the new subscription
        for(thisListener in newSubscriptionListeners.vals()){
          thisListener.1<system>(finalSub,trxId);
        };

        // Return the subscription response
      
        results.add(?#Ok {
            subscriptionId = finalSub.subscriptionId;
            transactionId = trxId;
        })
      };

      cleanRecents();

      return Buffer.toArray(results);
    };

    private func cleanRecents(){
      let now = natnow();
      label proc for(thisItem in Map.entries(state.recentTrx)){
        if(thisItem.1 + state.minDrift  + state.trxWindow < now){
          ignore Map.remove(state.recentTrx, Map.bhash, thisItem.0);
        } else {
          break proc;
        };
      };
    };

    ///MARK: Unsubscribe
    public func cancel_subscription(caller: Principal, request: [{ 
      subscriptionId: Nat;
      reason: Text
    }]) : async* [CancelResult] {

      let results = Buffer.Buffer<CancelResult>(1);

      label proc for(thisItem in request.vals()){
        let subscriptionId = thisItem.subscriptionId;
        let reason = thisItem.reason;

        // get the subscription
        let ?subscription = Map.get(state.subscriptions, Map.nhash, subscriptionId: Nat) else {
          results.add(?#Err(#NotFound));
          continue proc;
        };


        // validate that the caller is the subscriber or service
        if(subscription.account.owner != caller and subscription.serviceCanister != caller){
          results.add(?#Err(#Unauthorized));
          continue proc;
        };

        // cancel
        willCancelSubscription<system>(caller, reason, subscription);


        //create transaction record
        let (op,top) = Serializer.serializeSubCancel(subscription, reason, caller, natnow());
        let trxId = addRecord<system>(op, ?top);

        for(thisListener in canceledSubscriptionListeners.vals()){
          thisListener.1<system>(subscription,trxId);
        };
        results.add(?#Ok(trxId));
      };

      return Buffer.toArray(results);
    };


    ///MARK: Pause
    public func pause_subscription(caller: Principal, request: PauseRequest) : async* [PauseResult] {

      debug logDebug(debug_channel.announce, "Subs: pause_subscription" # debug_show(request));

      let results = Buffer.Buffer<PauseResult>(1);

      label proc for(thisItem in request.vals()){
        let subscriptionId = thisItem.subscriptionId;
        let reason = thisItem.reason;
        let active = thisItem.active;

        // get the subscription
        let ?subscription = Map.get(state.subscriptions, Map.nhash, subscriptionId: Nat) else {
          results.add(?#Err(#NotFound));
          continue proc;
        };

        // validate that the caller is the subscriber or service
        switch(subscription.status){
          case(#Paused(val)){
            debug logDebug(debug_channel.pause, "Subs: pause_subscription already paused" # debug_show(subscription));

            //if the canister paused then either the service or the owner can unpause
            if(val.1 == canister){
               if((caller != subscription.serviceCanister and caller != subscription.account.owner) or active == false){
                //only the oringinal pauser can unpause
                results.add(?#Err(#Unauthorized));
                continue proc;
              };
            } else {
              if((val.1 != caller ) or active == false){
                //only the oringinal pauser can unpause
                results.add(?#Err(#Unauthorized));
                continue proc;
              };
            };
            //reactivate.

            //how to handle reactivation
            activateSubscription<system>(caller, reason, subscription);

            let (op,top) = Serializer.serializeSubActivated(subscription, reason, caller, natnow());
            let trxId = addRecord<system>(op, ?top);

            for(thisListener in activateSubscriptionListeners.vals()){
              thisListener.1<system>(subscription,trxId);
            };
            results.add(?#Ok(trxId));
          };
          case(#Active(val)){
            debug logDebug(debug_channel.pause, "Subs: pause_subscription active" # debug_show(subscription));
            if(subscription.account.owner != caller and subscription.serviceCanister != caller){
              results.add(?#Err(#Unauthorized));
              continue proc;
            };
            if(active == true){
              results.add(?#Err(#Unauthorized));
              continue proc;
            };

            // pause
            pauseSubscription<system>(caller, reason, active, subscription);

            let (op,top) = Serializer.serializeSubPaused(subscription, reason, caller, natnow());
            let trxId = addRecord<system>(op, ?top);
            results.add(?#Ok(trxId));

            for(thisListener in pauseSubscriptionListeners.vals()){
              thisListener.1<system>(subscription, trxId);
            };
          };
          case(_){
            results.add(?#Err(#InvalidStatus(subscription.status)));
            continue proc;
          };
        };

      };

      return Buffer.toArray(results);
    };

    public func subaccountToBlob(aBlob : ?Blob) : Blob {
      switch(aBlob){
        case(null) nullSubaccount;
        case(?val) val;
      };
    };

    private func findOrCreateUserProductMap(subscription: SubscriptionState) : Set.Set<Nat> {

      debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap" # debug_show(subscription));
      
      let accountMap : SubAccountSubscriptionMap = switch(Map.get(state.userSubscriptionIndex, Map.phash, subscription.account.owner)){
        case(null) {

          debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap accountMap null" # debug_show(subscription.account.owner));
          let accountMap = Map.new<Blob, ServiceSubscriptionMap>();
          ignore Map.put<Principal,SubAccountSubscriptionMap>(state.userSubscriptionIndex, Map.phash, subscription.account.owner, accountMap);
          accountMap;
        };
        case(?val) val;
      };

      let subBlob = subaccountToBlob(subscription.account.subaccount);

      let serviceMap : ServiceSubscriptionMap = switch(Map.get(accountMap, Map.bhash, subBlob)){
        case(null) {
          debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap serviceMap null" # debug_show(subscription.account.subaccount));
          let serviceMap = Map.new<Principal, ProductSubscriptionMap>();
          ignore Map.put<Blob, ServiceSubscriptionMap>(accountMap, Map.bhash, subBlob, serviceMap);
          serviceMap;
        };
        case(?val) val;
      };

      let productSubMap = switch(Map.get(serviceMap, Map.phash, subscription.serviceCanister)){
        case(null) {
          debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap productMap null" # debug_show(subscription.serviceCanister));
          let productSubMap = Map.new<?Nat, Set.Set<Nat>>();
          ignore Map.put(serviceMap, Map.phash, subscription.serviceCanister, productSubMap);
          productSubMap;
        };
        case(?val) val;
      };

      let productMap = switch(Map.get(productSubMap, nullNHash, subscription.productId)){
        case(null) {
          debug logDebug(debug_channel.subscribe, "Subs: findOrCreateUserProductMap productMap null" # debug_show(subscription.productId));
          let productMap = Set.new<Nat>();
          ignore Map.put(productSubMap, nullNHash, subscription.productId, productMap);
          productMap;
        };
        case(?val) val;
      };

      productMap;
    };

    private func findOrCreateServiceProductMap(subscription: SubscriptionState) : Set.Set<Nat> {

      debug logDebug(debug_channel.subscribe, "Subs: findOrCreateServiceProductMap" # debug_show(subscription));
      let productSubMap = switch(Map.get(state.serviceSubscriptionIndex, Map.phash, subscription.serviceCanister)){
        case(null) {
          debug logDebug(debug_channel.subscribe, "Subs: findOrCreateServiceProductMap productMap null" # debug_show(subscription.serviceCanister));
          let productSubMap = Map.new<?Nat, Set.Set<Nat>>();
          ignore Map.put(state.serviceSubscriptionIndex, Map.phash, subscription.serviceCanister, productSubMap);
          productSubMap;
        };
        case(?val) val;
      };

      let productMap = switch(Map.get(productSubMap, nullNHash, subscription.productId)){
        case(null) {
          debug logDebug(debug_channel.subscribe, "Subs: findOrCreateServiceProductMap productMap null" # debug_show(subscription.productId));
          let productMap = Set.new<Nat>();
          ignore Map.put(productSubMap, nullNHash, subscription.productId, productMap);
          productMap;
        };
        case(?val) val;
      };
      productMap;
    };

    private func fileSubscription(subscription: SubscriptionState) : () {

      // Add the subscription to the userIndex
      
      let userProductMap = findOrCreateUserProductMap(subscription);
      let serviceProductMap = findOrCreateServiceProductMap(subscription);

      ignore Set.put(userProductMap, Set.nhash, subscription.subscriptionId);

      ignore Set.put(serviceProductMap, Set.nhash, subscription.subscriptionId);

      // Add the subscription to the globalmap
      ignore Map.put(state.subscriptions, Map.nhash, subscription.subscriptionId, subscription);
    };

    private func willCancelSubscription<system>(caller: Principal, reason: Text, subscription: SubscriptionState) : () {

      // Add the subscription to the userIndex
      subscription.status := #WillCancel(natnow(), caller, reason);

      //log notification
      let notificationId = fileNotification(subscription, #SubscriptionEnded{principal = caller; subscriptionId = subscription.subscriptionId; reason = reason;});

      //stop the timer
      switch(subscription.nextTimerId){
        case(null){};
        case(?val) ignore environment.tt.cancelAction<system>(val.id);
      };
      
      return;

    };

    private func pauseSubscription<system>(caller: Principal, reason: Text, active: Bool, subscription: SubscriptionState) : () {

      //note: this function does not validate the caller, it is assumed that the caller has already been validated

      subscription.status := #Paused(natnow(), caller, reason);
      subscription.nextPayment := null;
      subscription.nextPaymentAmount := null;

      //turn off the timer
      switch(subscription.nextTimerId){
        case(null){};
        case(?val) ignore environment.tt.cancelAction<system>(val.id);
      };

      fileNotification(subscription, #SubscriptionPaused{principal = caller; subscriptionId = subscription.subscriptionId; reason = reason;});

      return;

    };

    private func activateSubscription<system>(caller: Principal, reason: Text, subscription: SubscriptionState) : () {

      //note: this function does not validate the caller, it is assumed that the caller has already been validated

      subscription.status := #Active;

      fileNotification(subscription, #SubscriptionActivated{principal = caller; subscriptionId = subscription.subscriptionId; reason = reason;});
      debug logDebug(debug_channel.announce, "Subs: activateSubscription scheduling immediate Payment" # debug_show((natnow(), subscription.amountPerInterval)));
      subscription.nextPayment := ?natnow();
      subscription.nextPaymentAmount := ?subscription.amountPerInterval;
      subscription.nextTimerId := ?environment.tt.setActionASync<system>(natnow(), {
          actionType = "subscriptionPayment";
          params = to_candid({
            subscriptionId = subscription.subscriptionId;
            amountAtSet = subscription.amountPerInterval;
            timeAtSet = natnow();
            retries = 0;
          });
        }, ONE_MINUTE * 5);
    
     
      
      return;

    };

  private func calculateMaxAllowance(request: SubscriptionStateShared, totalSupply: Nat, fee: Nat) : Nat {
    debug logDebug(debug_channel.subscribe, "Subs: calculateMaxAllowance" # debug_show((request, totalSupply, fee)));
      if (request.baseRateAsset != null) {
          totalSupply / 2
      } else if (request.endDate != null) {
          let totalPayments = calculateTotalPayments(request, totalSupply);
          totalPayments.0 + (fee * totalPayments.1)
      } else {
          totalSupply / 2
      }
  };

  private func calculateTotalPayments(request: SubscriptionStateShared, totalSupply: Nat) : (Nat, Nat) {
    debug logDebug(debug_channel.subscribe, "Subs: calculateTotalPayments" # debug_show((request, totalSupply)));

      let ?endDate = request.endDate else return ((totalSupply/2, 0));
      let intervalNanoSeconds = intervalToNanoSeconds(request.interval);
      if (intervalNanoSeconds == 0) {
          return ((totalSupply/2, 0));
      };
      let totalIntervals = if(endDate > natnow()){
        ((endDate - natnow()) / intervalNanoSeconds);
      } else {
        0;
      };
      (totalIntervals * request.amountPerInterval, totalIntervals)
  };

  public func intervalToNanoSeconds(interval: Interval) : Nat {
    switch interval {
      case (#Hourly) 3_600_000_000_000;
      case (#Daily) 86_400_000_000_000;
      case (#Weekly) 604_800_000_000_000;
      case (#Monthly) 2_629_800_000_000_000;
      case (#Yearly) 31_557_600_000_000_000;
      case (#Interval(n)) n;
      case (#Days(d)) d * 86_400_000_000_000;
      case (#Weeks(w)) w * 604_800_000_000_000;
      case (#Months(m)) m * 2_629_800_000_000_000;
    }
  };

  private func trxMemo(subscriptionId : Nat, productId : ?Nat, paymentId : Nat, bFee : Bool) : Blob{
    let digest256 = Sha256.Digest(#sha256);
    digest256.writeBlob(Text.encodeUtf8("icrc79sub:"));
    digest256.writeArray(Conversion.natToBytes(subscriptionId));
    switch(productId){
      case(null)digest256.writeBlob(Text.encodeUtf8("pubnul"));
      case(?val) digest256.writeArray(Conversion.natToBytes(val));
    };
    digest256.writeArray(Conversion.natToBytes(paymentId));
    if(bFee){
      digest256.writeBlob(Text.encodeUtf8("fee"));
    };
    digest256.sum()
  };

  private func checkAllowance(tokenCanister: Principal, owner: Account, spender: Account, amount: Nat) : async* Result.Result<(), Nat> {

    let icrc2Actor : ICRC2Actor = actor(Principal.toText(tokenCanister));
      
    let result = try{
      await icrc2Actor.icrc2_allowance({
        account = owner; 
        spender = spender;
      });
    } catch(err){
      return #err(0);
    };

    if(result.allowance >= amount){
      return #ok;
    };
    return #err(result.allowance);
  };

  private func fileNotification(subscription: SubscriptionState, error: ServiceNotificationType) : () {
      let notificationId = state.nextNotificationId;

      let notificationMap = switch(Map.get(state.notifications, Map.phash, subscription.serviceCanister)){
        case(null){
          let newNotificationMap = Map.new<Nat, ServiceNotification>();
          ignore Map.put(state.notifications, Map.phash, subscription.serviceCanister, newNotificationMap);
          newNotificationMap;
        };
        case(?val) val;
      };

      let newNotification = {
        notification = error;
        date = natnow();
        principal = subscription.serviceCanister;
      } : ServiceNotification;

      ignore Map.put<Nat, ServiceNotification>(notificationMap, Map.nhash, notificationId, newNotification);

      state.nextNotificationId += 1;
  };

  private func handleSubscriptionPaymentError<system>(subscriptionDetails : ScheduledPaymentArgs, subscription: SubscriptionState, error: Text) : async () {

    debug logDebug(debug_channel.announce, "Subs: handleSubscriptionPaymentError" # debug_show((subscriptionDetails, subscription, error)));

      if(subscriptionDetails.retries > 10){
        //handle too many retries
        let notificationId = fileNotification(subscription, #LedgerError{error = error; rescheduled = null; subscriptionId = subscription.subscriptionId;});
        //only the user will be able to reactivate the subscription.
        pauseSubscription<system>(canister, "Too many retries", false, subscription);

        let (op,top) = Serializer.serializeSubPaused(subscription, "Too many retries", canister, natnow());
        let trxId = addRecord<system>(op, ?top);
        

        for(thisListener in pauseSubscriptionListeners.vals()){
          thisListener.1<system>(subscription, trxId);
        };
        return notificationId;
      } else {
        let nextTry = (natnow() + (ONE_MINUTE * 60));
        debug logDebug(debug_channel.announce, "Subs: handleSubscriptionPaymentError rescheduling" # debug_show(nextTry));

        subscription.nextTimerId := ?environment.tt.setActionASync<system>(nextTry, {
          actionType = "subscriptionPayment";
          params = to_candid({
            subscriptionId = subscription.subscriptionId;
            amountAtSet = subscriptionDetails.amountAtSet;
            timeAtSet = subscriptionDetails.timeAtSet;
            retries = subscriptionDetails.retries + 1;
          });
        }, ONE_MINUTE * 5);
        let notificationId = fileNotification(subscription, #LedgerError{error = error; rescheduled = ?nextTry; subscriptionId = subscription.subscriptionId;});
        return notificationId;
      };
  };

  var paymentsSinceShare = 0;

  ///MARK: Payments
  private func subscriptionPayment<system>(id: TT.ActionId, Action: TT.Action) : async* Star.Star<TT.ActionId, TT.Error> {

    debug logDebug(debug_channel.announce, "Subs: subscriptionPayment" # debug_show((id, Action)));
      // 1. Get the subscription using the `Action` parameter
    let ?subscriptionDetails : ?ScheduledPaymentArgs = from_candid(Action.params) else {
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment candid error" # debug_show(Action.params));
        return #err(#trappable({error_code = 5; message = "Candid Error" # debug_show(Action.params);}));
    };
    

    // 2. Retrieve the subscription from the global state
    let ?subscription = Map.get(state.subscriptions, Map.nhash, subscriptionDetails.subscriptionId) else {
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment subscription not found" # debug_show(subscriptionDetails.subscriptionId));
        return #err(#trappable({error_code = 2; message = "Subscription Not Found";}));
    };

    switch(subscription.status){
      case(#Active){};
      case(#WillCancel(ts, caller, reason)){
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment subscription is will cancel" # debug_show(subscription));
        //cancel the stubscription
        subscription.status := #Canceled(ts, natnow(), caller, reason);
        subscription.nextPayment := null;
        subscription.nextPaymentAmount := null;
        //create transaction record
        let (op,top) = Serializer.serializeSubCancel(subscription, reason, caller, natnow());
        let trxId = addRecord<system>(op, ?top);

        for(thisListener in canceledSubscriptionListeners.vals()){
          thisListener.1<system>(subscription,trxId);
        };
        return #awaited(id);
      };
      case(#Canceled(_)){
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment subscription is canceled" # debug_show(subscription));
        return #awaited(id);
      };
      case(#Paused(_)){
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment subscription is paused" # debug_show(subscription));
        return #awaited(id);
      };
    };

    // 3. Get the next payment info (amount and due date)
    let ?nextPaymentDate = subscription.nextPayment else {
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment nextPaymentDate not found" # debug_show(subscription)); 
        return  #err(#trappable({error_code = 3; message = "Next payment date is not set.";}));
    };

    let ?nextPaymentAmount = subscription.nextPaymentAmount else {
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment nextPaymentAmount not found" # debug_show(subscription));
        return #err(#trappable({error_code = 4; message = "Next payment amount is not set.";}));
    };

    if(nextPaymentDate != subscriptionDetails.timeAtSet or nextPaymentAmount != subscriptionDetails.amountAtSet){
      //todo: handle if something changed
      debug logDebug(debug_channel.announce, "Subs: subscriptionPayment nextPaymentDate or nextPaymentAmount changed" # debug_show((nextPaymentDate, subscriptionDetails.timeAtSet, nextPaymentAmount, subscriptionDetails.amountAtSet)));
    };

    let ?kt = Map.get(state.tokenInfo, ktHash, (subscription.tokenCanister, subscription.tokenPointer)) else {
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment token not found" # debug_show(subscription));
        return #err(#trappable({error_code = 4; message = "Token not found.";}));
    };

    //lock in a payment rate
    let paymentId = state.nextPaymentId;
    state.nextPaymentId += 1;

    //determine the exchange rate

    let (amountBeforeFee, rateUsed : ?ExchangeRate) = switch(subscription.baseRateAsset){
      case(null) (nextPaymentAmount, null);
      case(?val) {
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment baseRateAsset" # debug_show(val));
        
        //get the base rate.
        let exchangeRateActor : Service.ExchangeRateActor = actor(Principal.toText(state.exchangeRateCanister));

        let rate = try {
          ExperimentalCycles.add<system>(1_000_000_000);
          let rate = await exchangeRateActor.get_exchange_rate({
            timestamp = ?nat64now();
            quote_asset = val;
            base_asset = {
            class_ =#Cryptocurrency;
            symbol = kt.tokenSymbol;
            };
          });
          rate;
        } catch (error) {
          ignore handleSubscriptionPaymentError<system>(subscriptionDetails, subscription, Error.message(error));
          return #awaited(id);
        };

        switch(rate){
          case(#Ok(val)){
            ((nextPaymentAmount * Nat64.toNat(val.rate))/((10 : Nat) ** Nat32.toNat(val.metadata.decimals)), ?val);
          };
          case(#Err(err)){
            ignore handleSubscriptionPaymentError<system>(subscriptionDetails, subscription, debug_show(err));
            return #awaited(id);
          };
        };

      };
    };

    debug logDebug(debug_channel.announce, "Subs: subscriptionPayment amountBeforeFee" # debug_show(amountBeforeFee));

    //pay the fee if possible
    let (total, fee) = switch(getFeeDetails(subscription)){
      case(?val){
        if(val.1 >= 10000) { //over 10000 basis points
          return #err(#trappable({error_code = 4; message = "Fee too high.";}));
        };
        var feeAmount = (amountBeforeFee * val.1) / 10000;
        let totalAmount = if(feeAmount > amountBeforeFee){
          feeAmount := 0;
          amountBeforeFee;
        } else {
          amountBeforeFee - feeAmount;
        };
        (totalAmount, feeAmount);
      };
      case(null){
        (amountBeforeFee, 0);
      };
    };

    debug logDebug(debug_channel.announce, "Subs: subscriptionPayment total" # debug_show((total,fee)));


    // 4. Execute the payment
    if(isICRC80(kt)){
      //todo: handle icrc80
      return #err(#trappable({error_code = 4; message = "ICRC80 not supported.";}));
    } else {
      debug logDebug(debug_channel.announce, "Subs: subscriptionPayment icrc2" # debug_show(subscription));
      let icrc2Actor : ICRC2Actor = actor(Principal.toText(subscription.tokenCanister));

      let transferResult = try{
          await icrc2Actor.icrc2_transfer_from({
            from = subscription.account;
            to = switch(subscription.targetAccount){
                case(null) {{ owner = subscription.serviceCanister; subaccount = null }};
                case(?targetAccount) targetAccount;
            };
            amount = total;
            fee = kt.tokenFee;
            spender_subaccount = null;
            memo = ?trxMemo(subscription.subscriptionId, subscription.productId, paymentId, true); 
            from_subaccount = subscription.account.subaccount;
            created_at_time = ?nat64now();
        });
      } catch (error) {
        debug logDebug(debug_channel.announce, "Subs: subscriptionPayment error" # Error.message(error));
        ignore handleSubscriptionPaymentError<system>(subscriptionDetails, subscription, Error.message(error));
        return #awaited(id);
      };

    // 5. Handle any errors during the payment
    switch (transferResult) {
      case (#Err(err)) {
          debug logDebug(debug_channel.announce, "Subs: subscriptionPayment transferResult" # debug_show(err));
          ignore handleSubscriptionPaymentError<system>(subscriptionDetails, subscription, debug_show(err));
          return #awaited(id);
      };
      case (#Ok(transactionId)) {
          // 6. Record the payment in the history
          debug logDebug(debug_channel.announce, "Subs: subscriptionPayment transactionId" # debug_show(transactionId));
          
          //add the payment:
          let newPayment : PaymentRecord = {
            paymentId = paymentId;
            date = natnow();
            var brokerFee = null;
            var brokerTransactionId = null;
            var transactionId = ?transactionId;
            subscriptionId = subscription.subscriptionId;
            amount = total;
            rate = rateUsed;
            var ledgerTransactionId = ?transactionId;
            subscription = subscription.subscriptionId;
            var feeTransactionId = null;
            var fee = null;
            time = natnow();
            result = #Ok;
          };

          debug logDebug(debug_channel.announce, "Subs: subscriptionPayment newPaymentRecord" # debug_show(newPayment));

          Vector.add(subscription.history, paymentId);
          ignore Map.put(state.payments, Map.nhash, paymentId, newPayment);
          subscription.nextPaymentAmount := null; // Clear the next payment amount

          // 7. Schedule the next payment if not past the end date
          let (nextPayment, nextPaymentAmount) = switch(subscription.endDate) {
              case (?endDate){ 
                  if (subscriptionDetails.timeAtSet + intervalToNanoSeconds(subscription.interval) > endDate) {
                      subscription.status := #Canceled(natnow(), natnow(), canister, "Expired");
                      subscription.nextPayment := null;
                      subscription.nextPaymentAmount := null;
                  } else {
                    subscription.nextPayment := ?(subscriptionDetails.timeAtSet + intervalToNanoSeconds(subscription.interval));
                    subscription.nextPaymentAmount := ?subscription.amountPerInterval;
                    
                  };
                  (subscription.nextPayment, subscription.nextPaymentAmount);
              };
              case (_) {
                  debug logDebug(debug_channel.announce, "Subs: subscriptionPayment enddate not found" # debug_show(subscription));
                  subscription.nextPayment := ?(nextPaymentDate + intervalToNanoSeconds(subscription.interval));
                  subscription.nextPaymentAmount := ?subscription.amountPerInterval;

                  (subscription.nextPayment, subscription.nextPaymentAmount);
              };
          };

          switch(nextPayment, nextPaymentAmount){
            case(?valDate, ?valAmount){
              debug logDebug(debug_channel.announce, "Subs: subscriptionPayment scheduling nextPayment" # debug_show((valDate, valAmount)));

              subscription.nextTimerId := ?environment.tt.setActionASync<system>(valDate, {
                          actionType = "subscriptionPayment";
                          params = to_candid({
                              subscriptionId = subscription.subscriptionId;
                              amountAtSet = valAmount;
                              timeAtSet = valDate;
                              retries = 0;
                          } : ScheduledPaymentArgs);
                      }, ONE_MINUTE * 5);
            };
            case(_, _){
              debug logDebug(debug_channel.unreachable, "nextpayment was not set because none exists" # debug_show((nextPayment, nextPaymentAmount)));
            };
          };

          // 8. attempt to send the fee

          var bSendFee = switch(environment.canSendFee){
            case(null) true;
            case(?val) {
              val({
                service = subscription.serviceCanister;
                targetAccount = subscription.targetAccount;
                subscribingAccount = subscription.account;
                feeAccount = state.publicGoodsAccount;
                token = (subscription.tokenCanister, subscription.tokenPointer);
                feeAmount = fee}
                );
            };
          };

          debug logDebug(debug_channel.announce, "Subs: subscriptionPayment bSendFee" # debug_show(bSendFee));
          
          if(fee > 0 and bSendFee){
      
            let feeResult = try{
              await icrc2Actor.icrc2_transfer_from({
                from = subscription.account;
                to = state.publicGoodsAccount;
                amount = fee;
                fee = kt.tokenFee;
                spender_subaccount = null;
                memo = ?trxMemo(subscription.subscriptionId, subscription.productId, newPayment.paymentId, true);
                from_subaccount = subscription.account.subaccount;
                created_at_time = ?nat64now();
              });
            } catch (error) {
              //if the fee fails, then we just continue
              //ignore handleSubscriptionPaymentError<system>(subscriptionDetails, subscription, Error.message(error));
              debug logDebug(debug_channel.announce, "Subs: subscriptionPayment fee error" # Error.message(error));
              #Err(#GenericError({message = Error.message(error); error_code =1}));
            };

            switch(feeResult){
              case(#Err(err)){
                debug logDebug(debug_channel.announce, "Subs: subscriptionPayment feeResult" # debug_show(err));
                //ignore handleSubscriptionPaymentError<system>(subscriptionDetails, subscription, debug_show(err));
                //return #awaited(id);
                newPayment.fee := null;
                newPayment.feeTransactionId := null;
              };
              case(#Ok(transactionId)){
                debug logDebug(debug_channel.announce, "Subs: subscriptionPayment feeResult" # debug_show((transactionId, state.publicGoodsAccount)));
                newPayment.fee := ?fee;
                newPayment.feeTransactionId := ?transactionId;
              };
            };
          };

          //log the item to the ledger
          let (op,top) = Serializer.serializePaymentCreate(newPayment, natnow());

          let trx = switch(environment.addLedgerTransaction){
            case(null) 0; //todo : should we throw an error?
            case(?val) val<system>(op, ?top);
          };

          newPayment.transactionId := ?trx;

          paymentsSinceShare += 1;
          if(paymentsSinceShare >= 100){
            ignore environment.tt.setActionASync<system>(natnow(),{
              actionType = "shareAction";
              params = to_candid({});
            }, ONE_MINUTE * 5);
            paymentsSinceShare := 0;
          };
          

          // Return the action as successfully executed
          return #awaited(id);
      };
    };
    };

    
  };

  private func getFeeDetails(subscription : SubscriptionState) : ?(Account, Nat) {

    //todo: add filter for blocking fee payout

    return ?(state.publicGoodsAccount, state.feeBPS);
  };

  private func passesSubAccountFilter(filter: ?UserSubscriptionsFilter, subaccount: Blob) : Bool {
    switch(do?{filter!.subaccounts!}){
      case(null) true;
      case(?sub){
        if(Array.indexOf<?Blob>(?subaccount, sub, func(a : ?Blob, b: ?Blob){subAccountEqual(a,b)}) != null){
          true;
        } else {
          false;
        };
      };
    };
  };

  private func passesServiceFilter(filter: ?UserSubscriptionsFilter, principal: Principal) : Bool {
    switch(do?{filter!.services!}){
      case(null) true;
      case(?sub){
        if(Array.indexOf<Principal>(principal, sub, Principal.equal) != null){
          true;
        } else {
          false;
        };
      };
    };
  };

  private func passesProductFilter(filter: ?UserSubscriptionsFilter, productId: ?Nat) : Bool {
    switch(do?{filter!.products!}){
      case(null) true;
      case(?sub){
        if(Array.indexOf<?Nat>(productId, sub, func(a: ?Nat, b: ?Nat): Bool{
          switch(a,b){
            case(null, null) true;
            case(?a, ?b) a == b;
            case(_, _) false;
          };
          }) != null){
          true;
        } else {
          false;
        };
      };
    };
  };

  private func passesServiceProductFilter(filter: ?Service.ServiceSubscriptionFilter, productId: ?Nat) : Bool {
    switch(do?{filter!.products!}){
      case(null) true;
      case(?sub){
        if(Array.indexOf<?Nat>(productId, sub, func(a: ?Nat, b: ?Nat): Bool{
          switch(a,b){
            case(null, null) true;
            case(?a, ?b) a == b;
            case(_, _) false;
          };
          }) != null){
          true;
        } else {
          false;
        };
      };
    };
  };

  private func passesSubscriptionFilter(filter: ?UserSubscriptionsFilter, subscriptionId: Nat) : Bool {
    switch(do?{filter!.subscriptions!}){
      case(null) true;
      case(?sub){
        if(Array.indexOf<Nat>(subscriptionId, sub, Nat.equal) != null){
          true;
        } else {
          false;
        };
      };
    };
  };

  private func passesServiceSubscriptionFilter(filter: ?Service.ServiceSubscriptionFilter, subscriptionId: Nat) : Bool {
    switch(do?{filter!.subscriptions!}){
      case(null) true;
      case(?sub){
        if(Array.indexOf<Nat>(subscriptionId, sub, Nat.equal) != null){
          true;
        } else {
          false;
        };
      };
    };
  };

  //MARK: Queries
  public func get_user_payments(caller: Principal, filter: ?UserSubscriptionsFilter, prev: ?Nat, take: ?Nat) : [Service.PaymentRecord] {
    // Implementation of get user payments logic
    debug logDebug(debug_channel.announce, "Subs: get_user_payments" # debug_show((caller, filter, prev, take)));

    var bFound = switch(prev){
      case(null) true;
      case(?val) false;
    };

    let target = switch(prev){
      case(null) 0;
      case(?val) val;
    };

    let ?subs = Map.get(state.userSubscriptionIndex, Map.phash, caller) else return [];
    debug logDebug(debug_channel.announce, "Subs: get_user_payments index " # debug_show(subs));

    let results = Buffer.Buffer<Service.PaymentRecord>(1);

    label subaccounts for(subaccountRecord in Map.entries(subs)){
      debug logDebug(debug_channel.announce, "Subs: get_user_payments subaccount" # debug_show((subaccountRecord), passesSubAccountFilter(filter, subaccountRecord.0)));
      if(passesSubAccountFilter(filter, subaccountRecord.0) == false) continue subaccounts;
      label services for(thisService in Map.entries(subaccountRecord.1)){
        debug logDebug(debug_channel.announce, "Subs: get_user_payments service" # debug_show(thisService));
        if(passesServiceFilter(filter, thisService.0) == false) continue services;
        label productSubs for(thisProductSub in Map.entries(thisService.1)){
          if(passesProductFilter(filter, thisProductSub.0) == false) continue productSubs;
          label products for(thisProduct in Set.keys(thisProductSub.1)){
            debug logDebug(debug_channel.announce, "Subs: get_user_payments product" # debug_show(thisProduct));
            

            if(passesSubscriptionFilter(filter, thisProduct) == false) continue products;
            
            let ?subscription = Map.get(state.subscriptions, Map.nhash, thisProduct) else {
                debug logDebug(debug_channel.announce, "Subs: get_user_payments payment not found" # debug_show(thisProduct));
                continue products;
            };

            debug logDebug(debug_channel.announce, "Subs: get_user_payments subscription" # debug_show((subscription, Vector.toArray(subscription.history))));
          
            label payments for(payment in Vector.vals(subscription.history)){
              debug logDebug(debug_channel.announce, "Subs: get_user_payments payment" # debug_show(payment));
              let ?paymentRecord = Map.get(state.payments, Map.nhash, payment) else {
                debug logDebug(debug_channel.announce, "Subs: get_user_payments payment not found" # debug_show(payment));
                continue products;
              };

              if(bFound == false){
                if(paymentRecord.paymentId == target){
                  bFound := true;
                } else {
                  continue payments;
                };
              };
              
              results.add({
                paymentId = paymentRecord.paymentId;
                fee = paymentRecord.fee;
                amount = paymentRecord.amount;
                date = paymentRecord.date;
                brokerFee = paymentRecord.brokerFee;
                brokerTransactionId = paymentRecord.brokerTransactionId;
                rate = paymentRecord.rate;
                subscriptionId = paymentRecord.subscriptionId;
                result = paymentRecord.result;
                transactionId = paymentRecord.transactionId;
                ledgerTransactionId = paymentRecord.ledgerTransactionId;
                feeTransactionId = paymentRecord.feeTransactionId;
              });

              switch(take){
                case(null) {};
                case(?val){
                  if(results.size() >= val){
                    return Buffer.toArray(results);
                  };
                };
              };
            };
          };
          
        };
      };
    };

    Buffer.toArray(results);
  };

  public func get_payments_pending(caller: Principal, subscriptionIds: [Nat], ) : [?Service.PendingPayment] {
    // Implementation of get user payments logic
    debug logDebug(debug_channel.announce, "Subs: get_user_payments" # debug_show((caller, subscriptionIds)));

    if(caller != canister){
      if(subscriptionIds.size() > 100){
        D.trap("Too many subscriptions");
      };
    };

    let results = Buffer.Buffer<?Service.PendingPayment>(1);
    label subs for(sub in subscriptionIds.vals()){
      
          
      let ?subscription = Map.get(state.subscriptions, Map.nhash, sub) else {
          debug logDebug(debug_channel.announce, "Subs: get_user_payments payment not found" # debug_show(sub));
          results.add(null);
          continue subs;
      };

      switch(subscription.status){
        case(#Active){};
        case(#WillCancel(_)){};
        case(#Canceled(_)){
          results.add(null);
          continue subs;
        };
        case(#Paused(_)){
          results.add(null);
          continue subs;
        };
      };

      results.add(?{
        nextPaymentDate = subscription.nextPayment;
        nextPaymentAmount = subscription.nextPaymentAmount;
        subscription = shareSubscriptionState(subscription)
      });
    };

    Buffer.toArray(results);
  };

  public func get_sevice_payments(caller: Principal, filter: ?Service.ServiceSubscriptionFilter, prev: ?Nat, take: ?Nat) : [Service.PaymentRecord] {
    // Implementation of get user payments logic
    debug logDebug(debug_channel.announce, "Subs: get_sevice_payments" # debug_show((caller, filter, prev, take)));

    var bFound = switch(prev){
      case(null) true;
      case(?val) false;
    };

    let target = switch(prev){
      case(null) 0;
      case(?val) val;
    };

    let ?subs = Map.get(state.serviceSubscriptionIndex, Map.phash, caller) else return [];

    debug logDebug(debug_channel.announce, "Subs: get_sevice_payments index " # debug_show(subs));

    let results = Buffer.Buffer<Service.PaymentRecord>(1);

    
    label productSubs for(thisProductSub in Map.entries(subs)){
      if(passesServiceProductFilter(filter, thisProductSub.0) == false) continue productSubs;
      label products for(thisProduct in Set.keys(thisProductSub.1)){
        debug logDebug(debug_channel.announce, "Subs: get_sevice_payments product" # debug_show(thisProduct));
        
        if(passesServiceSubscriptionFilter(filter, thisProduct) == false) continue products;
        
        let ?subscription = Map.get(state.subscriptions, Map.nhash, thisProduct) else {
            debug logDebug(debug_channel.announce, "Subs: get_sevice_payments payment not found" # debug_show(thisProduct));
            continue products;
        };
        debug logDebug(debug_channel.announce, "Subs: get_sevice_payments subscription" # debug_show((subscription, Vector.toArray(subscription.history))));

        switch(filter){
          case(null) {};
          case(?val){
            switch(val.status){
              case(null) {};
              case(?#Active){
                switch(subscription.status){
                  case(#Active){};
                  case(_){
                    continue products;
                  };
                };
              };
              case(?#Canceled){
                switch(subscription.status){
                  case(#Canceled(_)){};
                  case(_){
                    continue products;
                  };
                };
              };
              case(?#Paused){
                switch(subscription.status){
                  case(#Paused(_)){};
                  case(_){
                    continue products;
                  };
                };
              };
              case(?#WillCancel){
                switch(subscription.status){
                  case(#WillCancel(_)){};
                  case(_){
                    continue products;
                  };
                };
              };
            };
          };
        };

        for(thisPayment in Vector.vals(subscription.history)){

          if(bFound == false){
            if(thisPayment == target){
              bFound := true;
            } else {
              continue products;
            };
          };

          

          let ?paymentRecord = Map.get(state.payments, Map.nhash, thisPayment) else {
            debug logDebug(debug_channel.announce, "Subs: get_sevice_payments payment not found" # debug_show(thisProduct));
            continue products;
          };

          results.add({
            paymentId = paymentRecord.paymentId;
            fee = paymentRecord.fee;
            amount = paymentRecord.amount;
            date = paymentRecord.date;
            brokerFee = paymentRecord.brokerFee;
            brokerTransactionId = paymentRecord.brokerTransactionId;
            rate = paymentRecord.rate;
            subscriptionId = paymentRecord.subscriptionId;
            result = paymentRecord.result;
            transactionId = paymentRecord.transactionId;
            ledgerTransactionId = paymentRecord.ledgerTransactionId;
            feeTransactionId = paymentRecord.feeTransactionId;
          });

          switch(take){
            case(null) {};
            case(?val){
              if(results.size() >= val){
                return Buffer.toArray(results);
              };
            };
          };
        };
      };
    };


    Buffer.toArray(results);
  };

public func get_user_subscriptions(caller: Principal, filter: ?UserSubscriptionsFilter, prev: ?Nat, take: ?Nat) : [Service.Subscription] {
    // Implementation of get user payments logic
    debug logDebug(debug_channel.announce, "Subs: get_user_subscriptions" # debug_show((caller, filter, prev, take)));

    var bFound = switch(prev){
      case(null) true;
      case(?val) false;
    };

    let target = switch(prev){
      case(null) 0;
      case(?val) val;
    };

    let ?subs = Map.get(state.userSubscriptionIndex, Map.phash, caller) else return [];
    debug logDebug(debug_channel.announce, "Subs: get_user_subscriptions index " # debug_show(subs));

    let results = Buffer.Buffer<Service.Subscription>(1);

    label subaccounts for(subaccountRecord in Map.entries(subs)){
      debug logDebug(debug_channel.announce, "Subs: get_user_subscriptions subaccount" # debug_show((subaccountRecord), passesSubAccountFilter(filter, subaccountRecord.0)));
      if(passesSubAccountFilter(filter, subaccountRecord.0) == false) continue subaccounts;
      label services for(thisService in Map.entries(subaccountRecord.1)){
        debug logDebug(debug_channel.announce, "Subs: get_user_subscriptions service" # debug_show(thisService));
        if(passesServiceFilter(filter, thisService.0) == false) continue services;
        label productSubs for(thisProductSubs in Map.entries(thisService.1)){
          if(passesProductFilter(filter, thisProductSubs.0) == false) continue productSubs;
          label products for(thisProduct in Set.keys(thisProductSubs.1)){
            debug logDebug(debug_channel.announce, "Subs: get_user_subscriptions product" # debug_show(thisProduct));
            

            if(passesSubscriptionFilter(filter, thisProduct) == false) continue products;
            
            let ?subscription = Map.get(state.subscriptions, Map.nhash, thisProduct) else {
                debug logDebug(debug_channel.announce, "Subs: get_user_subscriptions payment not found" # debug_show(thisProduct));
                continue products;
            };

            if(bFound == false){
              if(subscription.subscriptionId == target){
                bFound := true;
              } else {
                continue products;
              };
            };

            switch(filter){
              case(null) {};
              case(?val){
                switch(val.status){
                  case(null) {};
                  case(?#Active){
                    switch(subscription.status){
                      case(#Active){};
                      case(_){
                        continue products;
                      };
                    };
                  };
                  case(?#Canceled){
                    switch(subscription.status){
                      case(#Canceled(_)){};
                      case(_){
                        continue products;
                      };
                    };
                  };
                  case(?#Paused){
                    switch(subscription.status){
                      case(#Paused(_)){};
                      case(_){
                        continue products;
                      };
                    };
                  };
                  case(?#WillCancel){
                    switch(subscription.status){
                      case(#WillCancel(_)){};
                      case(_){
                        continue products;
                      };
                    };
                  };
                };
              };
            };
            
            results.add(shareSubscriptionState(subscription));

            switch(take){
              case(null) {};
              case(?val){
                if(results.size() >= val){
                  return Buffer.toArray(results);
                };
              };
            };
          };
          
        };
      };
    };

    Buffer.toArray(results);
  };

  public func get_sevice_subscriptions(caller: Principal, filter: ?Service.ServiceSubscriptionFilter, prev: ?Nat, take: ?Nat) : [Service.Subscription] {
      // Implementation of get user payments logic
      debug logDebug(debug_channel.announce, "Subs: get_sevice_subscriptions" # debug_show((caller, filter, prev, take)));

      var bFound = switch(prev){
        case(null) true;
        case(?val) false;
      };

      let target = switch(prev){
        case(null) 0;
        case(?val) val;
      };

      let ?subs = Map.get(state.serviceSubscriptionIndex, Map.phash, caller) else return [];

      debug logDebug(debug_channel.announce, "Subs: get_sevice_subscriptions index " # debug_show(subs));

      let results = Buffer.Buffer<Service.Subscription>(1);

      
      label productSubs for(thisProductSubs in Map.entries(subs)){
        if(passesServiceProductFilter(filter, thisProductSubs.0) == false) continue productSubs;
        label products for(thisProduct in Set.keys(thisProductSubs.1)){
          debug logDebug(debug_channel.announce, "Subs: get_sevice_subscriptions product" # debug_show(thisProduct));
          

          
          if(passesServiceSubscriptionFilter(filter, thisProduct) == false) continue products;
          
          let ?subscription = Map.get(state.subscriptions, Map.nhash, thisProduct) else {
              debug logDebug(debug_channel.announce, "Subs: get_sevice_subscriptions payment not found" # debug_show(thisProduct));
              continue products;
          };



          debug logDebug(debug_channel.announce, "Subs: get_sevice_subscriptions subscription" # debug_show((subscription, Vector.toArray(subscription.history))));

          if(bFound == false){
            if(subscription.subscriptionId == target){
              bFound := true;
            } else {
              continue products;
            };
          };

          switch(filter){
            case(null) {};
            case(?val){
              switch(val.status){
                case(null) {};
                case(?#Active){
                  switch(subscription.status){
                    case(#Active){};
                    case(_){
                      continue products;
                    };
                  };
                };
                case(?#Canceled){
                  switch(subscription.status){
                    case(#Canceled(_)){};
                    case(_){
                      continue products;
                    };
                  };
                };
                case(?#Paused){
                  switch(subscription.status){
                    case(#Paused(_)){};
                    case(_){
                      continue products;
                    };
                  };
                };
                case(?#WillCancel){
                  switch(subscription.status){
                    case(#WillCancel(_)){};
                    case(_){
                      continue products;
                    };
                  };
                };
              };
            };
          };

          results.add(shareSubscriptionState(subscription));

          switch(take){
            case(null) {};
            case(?val){
              if(results.size() >= val){
                return Buffer.toArray(results);
              };
            };
          };
        };
      };

      Buffer.toArray(results);
    };

    public func get_service_notifications(caller: Principal, principal: Principal, prev: ?Nat, take: ?Nat) : [ServiceNotification] {


      debug logDebug(debug_channel.announce, "Subs: get_service_notifications" # debug_show((caller, principal, prev, take)));

      var bFound = switch(prev){
        case(null) true;
        case(?val) false;
      };

      let target = switch(prev){
        case(null) 0;
        case(?val) val;
      };

      let ?notifications = Map.get(state.notifications, Map.phash, principal) else return [];

      debug logDebug(debug_channel.announce, "Subs: get_service_notifications index " # debug_show(notifications));

      let results = Buffer.Buffer<ServiceNotification>(1);

      
      label proc for(thisNote in Map.entries(notifications)){
        debug logDebug(debug_channel.announce, "Subs: get_service_notifications " # debug_show(thisNote));

        if(bFound == false){
          if(thisNote.0 == target){
            bFound := true;
          } else {
            continue proc;
          };
        };

        results.add(thisNote.1);

        switch(take){
          case(null) {};
          case(?val){
            if(results.size() >= val){
              return Buffer.toArray(results);
            };
          };
        };
    
        
      };


      Buffer.toArray(results);

    };

    //MARK: Listeners

    type Listener<T> = (Text, T);

    private let newSubscriptionListeners = Buffer.Buffer<(Text, NewSubscriptionListener)>(1);

    private let canceledSubscriptionListeners = Buffer.Buffer<(Text, CanceledSubscriptionListener)>(1);

    private let newPaymentListeners = Buffer.Buffer<(Text, NewPaymentListener)>(1);

    private let activateSubscriptionListeners = Buffer.Buffer<(Text, ActivateSubscriptionListener)>(1);

    private let pauseSubscriptionListeners = Buffer.Buffer<(Text, PauseSubscriptionListener)>(1);

    /// Generic function to register a listener.
    ///
    /// Parameters:
    ///     namespace: Text - The namespace identifying the listener.
    ///     remote_func: T - A callback function to be invoked.
    ///     listeners: Vec<Listener<T>> - The list of listeners.
    public func registerListener<T>(namespace: Text, remote_func: T, listeners: Buffer.Buffer<Listener<T>>) {
      let listener: Listener<T> = (namespace, remote_func);
      switch(Buffer.indexOf<Listener<T>>(listener, listeners, func(a: Listener<T>, b: Listener<T>) : Bool {
        Text.equal(a.0, b.0);
      })){
        case(?index){
          listeners.put(index, listener);
        };
        case(null){
          listeners.add(listener);
        };
      };
    };

    /// `registerPublicationRegisteredListener`
    ///
    /// Registers a new listener or updates an existing one in the provided `listeners` vector.
    ///
    /// Parameters:
    /// - `namespace`: A unique namespace used to identify the listener.
    /// - `remote_func`: The listener's callback function.
    /// - `listeners`: The vector of existing listeners that the new listener will be added to or updated in.
    public func registerNewSubscriptionListener(namespace: Text, remote_func : NewSubscriptionListener){
      registerListener<NewSubscriptionListener>(namespace, remote_func, newSubscriptionListeners);
    };

    public func registerCanceledSubscriptionListener(namespace: Text, remote_func : CanceledSubscriptionListener){
      registerListener<CanceledSubscriptionListener>(namespace, remote_func, canceledSubscriptionListeners);
    };

    public func registerNewPaymentListener(namespace: Text, remote_func : NewPaymentListener){
      registerListener<NewPaymentListener>(namespace, remote_func, newPaymentListeners);
    };

    public func registerPauseSubscriptionListener(namespace: Text, remote_func : PauseSubscriptionListener){
      registerListener<PauseSubscriptionListener>(namespace, remote_func, pauseSubscriptionListeners);
    };

    public func registerActivateSubscriptionListener(namespace: Text, remote_func : ActivateSubscriptionListener){
      registerListener<ActivateSubscriptionListener>(namespace, remote_func, activateSubscriptionListeners);
    };

    private func cycleShare<system>(id: TT.ActionId, Action: TT.Action) : async* Star.Star<TT.ActionId, TT.Error> {
      try{
        await* ovsFixed.shareCycles<system>({
          environment = do?{environment.advanced!.icrc85!};
          namespace = "com.panindustrial.libraries.icrc79";
          actions = 100;
          schedule = func <system>(period: Nat) : async* (){};
          cycles = 1_000_000_000; //1 xdr
        });
      } catch(e){
        debug logDebug(debug_channel.cycles, "error sharing cycles" # Error.message(e));
      };
      return #awaited(id);
    };

    environment.tt.registerExecutionListenerAsync(?"subscriptionPayment", subscriptionPayment);
    environment.tt.registerExecutionListenerAsync(?"shareAction", cycleShare);
  };

}