import D "mo:base/Debug";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Map "mo:map/Map";
import BTree "mo:stableheapbtreemap/BTree";

import MigrationTypes "../types";
import v0_2_0 "types";

module {


  private func fileSubscription(state: v0_2_0.State, subscription: v0_2_0.SubscriptionState) : () {
    let userProductMap = v0_2_0.findOrCreateUserProductMap(state, subscription);
    let serviceProductMap = v0_2_0.findOrCreateServiceProductMap(state, subscription);
    ignore v0_2_0.BTree.insert(userProductMap, Nat.compare, subscription.subscriptionId, true);
    ignore v0_2_0.BTree.insert(serviceProductMap, Nat.compare, subscription.subscriptionId, true);
  };

  public func upgrade(prev_migration_state: MigrationTypes.State, args: MigrationTypes.Args, caller: Principal): MigrationTypes.State {

    let oldState = switch (prev_migration_state) { case (#v0_1_0(#data(state))) state; case (_) D.trap("Unexpected migration state") };

    let newState : MigrationTypes.Current.State = {
      userSubscriptionIndex = oldState.userSubscriptionIndex;
      userSubscriptionIndex2 = BTree.init<Principal, v0_2_0.SubAccountSubscriptionMap2>(null);
      serviceSubscriptionIndex2 = BTree.init<Principal, v0_2_0.ProductSubscriptionMap2>(null);
      serviceSubscriptionIndex = oldState.serviceSubscriptionIndex;
      subscriptions = oldState.subscriptions;
      subscriptions2 = BTree.init<Nat, v0_2_0.SubscriptionState>(null);
      payments = oldState.payments;
      payments2 = BTree.init<Nat, v0_2_0.PaymentRecord2>(null);
      assetInfo = oldState.assetInfo;
      tokenInfo = oldState.tokenInfo;
      notifications = oldState.notifications;
      recentTrx = oldState.recentTrx;
      var nextNotificationId = oldState.nextNotificationId;
      var publicGoodsAccount = oldState.publicGoodsAccount;
      var nextSubscriptionId = oldState.nextSubscriptionId;
      var nextPaymentId = oldState.nextPaymentId;
      var exchangeRateCanister = oldState.exchangeRateCanister;
      var feeBPS = oldState.feeBPS;
      var maxTake = oldState.maxTake;
      var maxUpdates = oldState.maxUpdates;
      var maxQueries = oldState.maxQueries;
      var defaultTake = oldState.defaultTake;
      var trxWindow = oldState.trxWindow;
      var minDrift = oldState.minDrift;
      var maxMemoSize = oldState.maxMemoSize;
    };

    for(thisSub in Map.entries(oldState.subscriptions)){
      ignore v0_2_0.BTree.insert(newState.subscriptions2, Nat.compare, thisSub.0, thisSub.1);
    };

    //rebuild payment records
    for(thisPayment in Map.entries(oldState.payments)){
      let ?sub = Map.get(oldState.subscriptions, Map.nhash, thisPayment.1.subscriptionId) else D.trap("Subscription not found");
      let newPayment : v0_2_0.PaymentRecord2  = {
        paymentId = thisPayment.0;
        date = thisPayment.1.date;
        amount = thisPayment.1.amount;
        var fee = thisPayment.1.fee;
        var brokerFee = thisPayment.1.brokerFee;
        var brokerTransactionId = thisPayment.1.brokerTransactionId;
        rate = thisPayment.1.rate;
        var ledgerTransactionId = thisPayment.1.ledgerTransactionId;
        var transactionId = thisPayment.1.transactionId;
        var feeTransactionId = thisPayment.1.fee;
        subscriptionId = thisPayment.1.subscriptionId;
        productId = sub.productId;
        service = sub.serviceCanister;
        targetAccount = sub.targetAccount;
        account = sub.account;
        result = thisPayment.1.result;
      };

      ignore v0_2_0.BTree.insert(newState.payments2, Nat.compare, thisPayment.0, newPayment);
    };


    //rebuild user and service Index
    for(thisItem in Map.entries(oldState.subscriptions)){
      fileSubscription(newState, thisItem.1);
    };
    
    //rebuild service Index
    return #v0_2_0(#data(newState));
  };

};