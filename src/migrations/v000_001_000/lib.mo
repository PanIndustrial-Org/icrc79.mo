import D "mo:base/Debug";
import Blob "mo:base/Blob";
import Opt "mo:base/Option";
import Principal "mo:base/Principal";
import Map "mo:map/Map";
import Set "mo:map/Set";
import Vec "mo:vector";

import MigrationTypes "../types";
import v0_1_0 "types";

module {

  private func initNextSubscriptionID(choice: ?Nat) : Nat{
    let ?nextId = choice else return 0;
    return nextId;
  };

  private func initNextPaymentID(choice: ?Nat) : Nat{
    let ?nextId = choice else return 0;
    return nextId;
  };

  private func initDefaultTake(choice: ?Nat) : Nat{
    let ?val = choice else return 100;
    return val;
  };

  private func initFeeBPS(choice: ?Nat) : Nat{
    let ?val = choice else return 150;
    return val;
  };

  private func initMaxUpdates(choice: ?Nat) : Nat{
    let ?val = choice else return 100;
    return val;
  };

  private func initMaxQueries(choice: ?Nat) : Nat{
    let ?val = choice else return 100;
    return val;
  };  

  private func initMaxTake(choice: ?Nat) : Nat{
    let ?val = choice else return 100;
    return val;
  };

  private func initTrxWindow(choice: ?Nat) : Nat{
    let ?val = choice else return 86_400_000_000_000;
    return val;
  };

  private func initMinDrift(choice: ?Nat) : Nat{
    let ?val = choice else return 60_000_000_000;
    return val;
  };

  private func initMemoSize(choice: ?Nat) : Nat{
    let ?val = choice else return 32;
    return val;
  };

  public func upgrade(prevmigration_state: MigrationTypes.State, args: MigrationTypes.Args, caller: Principal): MigrationTypes.State {

    let defaultPublicGoodsAccount = {owner = Principal.fromText("agtsn-xyaaa-aaaag-ak3kq-cai");
          subaccount = ?Blob.fromArray([39,167,236,212,75,183,197,29,163,240,112,67,54,45,238,71,220,227,55,132,102,170,154,183,149,180,185,26,233,48,38,105]);};//org.icdevs.subscription.collector

    let (
      existing_subs, 
      serviceIndex, 
      userIndex,
      publicGoodsAccount,
      nextSubscriptionId,
      nextPaymentId,
      defaultTake,
      feeBPS,
      maxUpdates,
      maxQueries,
      maxTake,
      trxWindow,
      minDrift,
      maxMemoSize,
      knownTokens
      ) = switch(args){
      case(?args){
         if((args.existingSubscriptions.size()) == 0) {
          (
            Map.new<Nat, v0_1_0.SubscriptionState>(),
            Map.new<Principal, v0_1_0.ProductSubscriptionMap>(),
            Map.new<Principal, v0_1_0.SubAccountSubscriptionMap>(),
            switch(args.publicGoodsAccount){
              case(null) defaultPublicGoodsAccount;
              case(?val) val;
            },
            initNextSubscriptionID(args.nextSubscriptionId),
            initNextPaymentID(args.nextPaymentId),
            initDefaultTake(args.defaultTake),
            initFeeBPS(args.feeBPS),
            initMaxUpdates(args.maxUpdates),
            initMaxQueries(args.maxQueries),
            initMaxTake(args.maxTake),
            initTrxWindow(args.trxWindow),
            initMinDrift(args.minDrift),
            initMemoSize(args.maxMemoSize),
            switch(args.tokenInfo){
              case(null) Map.new<(Principal, ?Blob), v0_1_0.TokenInfo>();
              case(?val) Map.fromIter<(Principal, ?Blob), v0_1_0.TokenInfo>(val.vals(), v0_1_0.ktHash);
            }

          );
        } else {
          //todo: convert existing subscriptions and payments
          (
            Map.new<Nat, v0_1_0.SubscriptionState>(),
            Map.new<Principal, v0_1_0.ProductSubscriptionMap>(),
            Map.new<Principal, v0_1_0.SubAccountSubscriptionMap>(),
            switch(args.publicGoodsAccount){
              case(null) defaultPublicGoodsAccount;
              case(?val) val;
            },
            initNextSubscriptionID(args.nextSubscriptionId),
            initNextPaymentID(args.nextPaymentId),
            initDefaultTake(args.defaultTake),
            initFeeBPS(args.feeBPS),
            initMaxUpdates(args.maxUpdates),
            initMaxQueries(args.maxQueries),
            initMaxTake(args.maxTake),
            initTrxWindow(args.trxWindow),
            initMinDrift(args.minDrift),
            initMemoSize(args.maxMemoSize),
            switch(args.tokenInfo){
              case(null) Map.new<(Principal, ?Blob), v0_1_0.TokenInfo>();
              case(?val) Map.fromIter<(Principal, ?Blob), v0_1_0.TokenInfo>(val.vals(), v0_1_0.ktHash);
            }
          );
        };
      };
      case(null){
        (
          Map.new<Nat, v0_1_0.SubscriptionState>(),
          Map.new<Principal, v0_1_0.ProductSubscriptionMap>(),
          Map.new<Principal, v0_1_0.SubAccountSubscriptionMap>(),
          defaultPublicGoodsAccount,
          0,
          0,
            initDefaultTake(null),
            initFeeBPS(null),
            initMaxUpdates(null),
            initMaxQueries(null),
            initMaxTake(null),
            initTrxWindow(null),
            initMinDrift(null),
            initMemoSize(null),
            Map.new<(Principal, ?Blob), v0_1_0.TokenInfo>()
        );
      };
    };

    let state : v0_1_0.State = {
      userSubscriptionIndex = userIndex;
      serviceSubscriptionIndex = serviceIndex;
      subscriptions = existing_subs;
      payments = Map.new<Nat, v0_1_0.PaymentRecord>();
      assetInfo = Set.new<v0_1_0.Asset>();
      tokenInfo = knownTokens;
      notifications = Map.new<Principal, v0_1_0.Map.Map<Nat, v0_1_0.ServiceNotification>>();
      recentTrx = Map.new<Blob, Nat>();
      var nextNotificationId = 0;
      var publicGoodsAccount = publicGoodsAccount;
      var nextSubscriptionId = nextSubscriptionId;
      var nextPaymentId = nextPaymentId;
      var exchangeRateCanister = Principal.fromText("uf6dk-hyaaa-aaaaq-qaaaq-cai");
      var feeBPS = feeBPS;
      var maxTake = maxTake;
      var maxUpdates = maxUpdates;
      var maxQueries = maxQueries;
      var defaultTake = defaultTake;
      var trxWindow = trxWindow;
      var minDrift = minDrift;
      var maxMemoSize = maxMemoSize;
    };

    return #v0_1_0(#data(state));
  };

};