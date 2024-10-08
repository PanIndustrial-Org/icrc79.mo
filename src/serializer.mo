import Types "migrations/types";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

module {

    type SubStatus = Types.Current.SubStatus;
    type Interval = Types.Current.Interval;
    type SubscriptionState = Types.Current.SubscriptionState;
    type SubscriptionStateShared = Types.Current.SubscriptionStateShared;
    type ExchangeRate = Types.Current.ExchangeRate;
    type ExchangeRateMetadata = Types.Current.ExchangeRateMetadata;
    type Asset = Types.Current.Asset;
    type PaymentRecord = Types.Current.PaymentRecord;
    type Account = Types.Current.Account;
    type Value = Types.Current.Value;


    public func statusToText(status: SubStatus) : Text {
      switch status {
        case (#Active) "Active";
        case (#Canceled(_)) "Canceled";
        case (#Paused(_)) "Paused";
        case (#WillCancel(_)) "WillCancel";
      };
    };

    public func intervalToText(interval: Interval) : Text {
      switch interval {
        case (#Hourly) "hourly";
        case (#Daily) "daily";
        case (#Weekly) "weekly";
        case (#Monthly) "monthly";
        case (#Yearly) "yearly";
        case (#Interval(n)) "interval";
        case (#Days(d)) "days";
        case (#Weeks(w)) "weeks";
        case (#Months(m)) "months";
      }
    };

    public func intervalToCount(interval: Interval) : ?Nat {
      switch interval {
        case (#Hourly) null;
        case (#Daily) null;
        case (#Weekly) null;
        case (#Monthly) null;
        case (#Yearly) null;
        case (#Interval(n)) ?n;
        case (#Days(d)) ?d;
        case (#Weeks(w)) ?w;
        case (#Months(m))?m;
      }
    };

    public func accountToValue(acc :Account) : Value {
        let vec = Buffer.Buffer<Types.Current.Value>(1);
        vec.add( #Blob(Principal.toBlob(acc.owner)));
        switch(acc.subaccount){
          case(null){};
          case(?val){
            vec.add( #Blob(val));
          };
        };

        return #Array(Buffer.toArray(vec));
    };

    public func serializeSubRequest(item: SubscriptionStateShared, caller: Principal, time: Nat) : (Value,Value) {
      //todo: add rate items when updating to flexible rates
      let items = Buffer.Buffer<(Text, Value)>(1);
      let top = Buffer.Buffer<(Text, Value)>(1);

      top.add( ("btype", #Text("79subRequest")));
      top.add( ("ts", #Nat(time))); 

      items.add( ("btype", #Text("79subRequest")));
      items.add( ("creator",#Blob(Principal.toBlob(caller))));
      items.add( ("tokenCanister",#Blob(Principal.toBlob(item.tokenCanister))));
      switch(item.tokenPointer){
        case(null){};
        case(?val) items.add( ("tokenPointer",#Blob(val)));
      };
      items.add( ("serviceCanister",#Blob(Principal.toBlob(item.serviceCanister))));
      items.add( ("interval",#Text(intervalToText(item.interval))));
      switch(intervalToCount(item.interval)){
        case(null){};
        case(?val) items.add( ("intervalAmt",#Nat(val)));
      };
      items.add( ("amtPerInterval",#Nat(item.amountPerInterval)));
      //todo: add the base rate asset
      switch(item.endDate){
        case(null){};
        case(?val) items.add( ("endDate",#Nat(val)));
      };
      switch(item.targetAccount){
        case(null){};
        case(?val) items.add( ("targetAccount",accountToValue(val)));
      };
      switch(item.productId){
        case(null){};
        case(?val) items.add( ("productId",#Nat(val)));
      };
      switch(item.memo){
        case(null){};
        case(?val) items.add( ("memo",#Blob(val)));
      };
      switch(item.createdAt){
        case(null){};
        case(?val) items.add( ("createdAt",#Nat(val)));
      };


      return (#Map(Buffer.toArray(items)), #Map(Buffer.toArray(top)));
    };

    public func serializeSubCreate(item: SubscriptionState, memo: ?Blob, created_at_time: ?Nat, caller: Principal, time: Nat) : (Value,Value) {
      let items = Buffer.Buffer<(Text, Value)>(1);
      let top = Buffer.Buffer<(Text, Value)>(1);

      top.add( ("btype", #Text("79subCreate")));
      top.add( ("ts", #Nat(time))); 
      //todo: add the base rate asset

      items.add( ("btype", #Text("79subCreate")));
      items.add( ("subscriptionId",#Nat(item.subscriptionId)));
      items.add( ("creator",#Blob(Principal.toBlob(caller))));
      switch(item.account.subaccount){
        case(null){};
        case(?val) items.add( ("subaccount", #Blob(val)));
      };
      items.add( ("tokenCanister",#Blob(Principal.toBlob(item.tokenCanister))));
      switch(item.tokenPointer){
        case(null){};
        case(?val) items.add( ("tokenPointer",#Blob(val)));
      };
      items.add( ("interval",#Text(intervalToText(item.interval))));
      switch(intervalToCount(item.interval)){
        case(null){};
        case(?val) items.add( ("intervalAmt",#Nat(val)));
      };
      items.add( ("amtPerInterval",#Nat(item.amountPerInterval)));
      switch(item.endDate){
        case(null){};
        case(?val) items.add( ("endDate",#Nat(val)));
      };
      switch(item.productId){
        case(null){};
        case(?val) items.add( ("productId",#Nat(val)));
      };
      switch(item.targetAccount){
        case(null){};
        case(?val) items.add( ("targetAccount",accountToValue(val)));
      };
      items.add( ("status",#Text(statusToText(item.status))));
      switch(item.brokerId){
        case(null){};
        case(?val) items.add( ("broker",accountToValue(val)));
      };
      switch(memo){
        case(null){};
        case(?val) items.add( ("memo",#Blob(val)));
      };
      switch(created_at_time){
        case(null){};
        case(?val) items.add( ("createdAt",#Nat(val)));
      };

      return (#Map(Buffer.toArray(items)), #Map(Buffer.toArray(top)));
    };

    public func serializeSubCancel(item: SubscriptionState, reason: Text, caller: Principal, time: Nat) : (Value,Value) {
      let items = Buffer.Buffer<(Text, Value)>(1);
      let top = Buffer.Buffer<(Text, Value)>(1);

      top.add( ("btype", #Text("79subCancel")));
      top.add( ("ts", #Nat(time))); 

      items.add( ("btype", #Text("79subCancel")));
      items.add( ("subscriptionId",#Nat(item.subscriptionId)));
      items.add( ("canceller",#Blob(Principal.toBlob(caller))));
      items.add( ("cancelReason",#Text(reason)));
      items.add( ("interval",#Text(intervalToText(item.interval))));
      items.add( ("canceledAt",#Nat(time)));

      return (#Map(Buffer.toArray(items)), #Map(Buffer.toArray(top)));
    };

    public func serializeSubActivated(item: SubscriptionState, reason: Text, caller: Principal, time: Nat) : (Value,Value) {
      let items = Buffer.Buffer<(Text, Value)>(1);
      let top = Buffer.Buffer<(Text, Value)>(1);

      top.add( ("btype", #Text("79subStatus")));
      top.add( ("ts", #Nat(time))); 

      items.add( ("btype", #Text("79subStatus")));
      items.add( ("subscriptionId",#Nat(item.subscriptionId)));
      items.add( ("caller",#Blob(Principal.toBlob(caller))));
      items.add( ("statusReason",#Text(reason)));
      items.add( ("newStatus", #Text(statusToText(item.status))));
      items.add( ("changeAt",#Nat(time)));

      return (#Map(Buffer.toArray(items)), #Map(Buffer.toArray(top)));
    };

    public func serializeSubPaused(item: SubscriptionState, reason: Text, caller: Principal, time: Nat) : (Value,Value) {
      let items = Buffer.Buffer<(Text, Value)>(1);
      let top = Buffer.Buffer<(Text, Value)>(1);

      top.add( ("btype", #Text("79subCancel")));
      top.add( ("ts", #Nat(time))); 

      items.add( ("btype", #Text("79subCancel")));
      items.add( ("subscriptionId",#Nat(item.subscriptionId)));
      items.add( ("canceller",#Blob(Principal.toBlob(caller))));
      items.add( ("cancelReason",#Text(reason)));
      items.add( ("interval",#Text(intervalToText(item.interval))));
      items.add( ("canceledAt",#Nat(time)));

      return (#Map(Buffer.toArray(items)), #Map(Buffer.toArray(top)));
    };

    public func serializeStatusChange(item: SubscriptionState, reason: Text, caller: Principal, time: Nat) : (Value,Value) {
      let items = Buffer.Buffer<(Text, Value)>(1);
      let top = Buffer.Buffer<(Text, Value)>(1);

      top.add( ("btype", #Text("79subStatus")));
      top.add( ("ts", #Nat(time))); 

      items.add( ("btype", #Text("79subStatus")));
      items.add( ("subscriptionId",#Nat(item.subscriptionId)));
      items.add( ("caller",#Blob(Principal.toBlob(caller))));
      items.add( ("statusReason",#Text(reason)));
      items.add( ("newStatus",#Text(statusToText(item.status))));
      items.add( ("changeAt",#Nat(time)));

      return (#Map(Buffer.toArray(items)), #Map(Buffer.toArray(top)));
    };

    public func serializeExchangeRate(item: ExchangeRate): Value{
      let items = Buffer.Buffer<(Text, Value)>(1);

      items.add( ("metadata",serializeExchangeRateMetadata(item.metadata)));
      items.add( ("rate", #Nat(Nat64.toNat(item.rate))));
      items.add( ("timestamp", #Nat(Nat64.toNat(item.timestamp))));
      items.add( ("quote_asset", serializeAsset(item.quote_asset)));
      items.add( ("base_asset", serializeAsset(item.base_asset)));

      return #Map(Buffer.toArray(items));

    };


  public func serializeAsset(item: Asset): Value {
    let items = Buffer.Buffer<(Text, Value)>(1);

    items.add( ("class", #Text(switch(item.class_){
      case(#Cryptocurrency) "Cryptocurrency";
      case(#FiatCurrency) "FiatCurrency";
    })));
    items.add( ("symbol", #Text(item.symbol)));

    return #Map(Buffer.toArray(items));
  };


  public func serializeExchangeRateMetadata(item: ExchangeRateMetadata): Value {
    let items = Buffer.Buffer<(Text, Value)>(1);

    items.add( ("decimals", #Nat(Nat32.toNat(item.decimals))));
    switch(item.forex_timestamp){
      case(null){};
      case(?val) items.add( ("forex_timestamp", #Nat(Nat64.toNat(val))));
    };
    items.add( ("quote_asset_num_received_rates", #Nat(Nat64.toNat(item.quote_asset_num_received_rates))));
    items.add( ("base_asset_num_received_rates", #Nat(Nat64.toNat(item.base_asset_num_received_rates))));
    items.add( ("base_asset_num_queried_sources", #Nat(Nat64.toNat(item.base_asset_num_queried_sources))));
    items.add( ("standard_deviation", #Nat(Nat64.toNat(item.standard_deviation))));
    items.add( ("quote_asset_num_queried_sources", #Nat(Nat64.toNat(item.quote_asset_num_queried_sources))));
    return #Map(Buffer.toArray(items));
  };


  public func serializePaymentCreate(item: PaymentRecord, time: Nat) : (Value,Value) {
    let items = Buffer.Buffer<(Text, Value)>(1);
    let top = Buffer.Buffer<(Text, Value)>(1);

    top.add( ("btype", #Text("79payment")));
    top.add( ("ts", #Nat(time))); 

    items.add( ("btype", #Text("79payment")));
    items.add( ("subscriptionId",#Nat(item.subscriptionId)));
    items.add( ("amount",#Nat(item.amount)));
    switch(item.rate){
      case(null){};
      case(?val) items.add( ("rate",serializeExchangeRate(val)));
    };
    switch(item.ledgerTransactionId){
      case(null){};
      case(?val) items.add( ("ledgerTransactionId",#Nat(val)));
    };
    switch(item.feeTransactionId){
      case(null){};
      case(?val) items.add( ("feeTransactionId",#Nat(val)));
    };
    items.add( ("date", #Nat(item.date)));
    switch(item.fee){
      case(null){};
      case(?val) items.add( ("fee",#Nat(val)));
    };

    return (#Map(Buffer.toArray(items)), #Map(Buffer.toArray(top)));
  };

}