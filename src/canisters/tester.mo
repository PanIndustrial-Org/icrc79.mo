
import Buffer "mo:base/Buffer";
import D "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat8 "mo:base/Nat8";

import Service "../Service";
import ICRC79 "../";
import ICRC79MigrationTypes "../migrations/types";
import ICRC79Migrations "../migrations";
import TT "mo:timer-tool";


shared (deployer) actor class Tester() = this {

  let debug_channel = {
    announce = true;
  };

  public shared func checksubscription(principal: Principal, subscriptionIds: [Nat], cycles: Nat) : async [Service.ConfirmResult] {

    let results = Buffer.Buffer<Service.ConfirmResult>(1);

    let anActor : Service.Service = actor(Principal.toText(principal));

    for(subscriptionId in subscriptionIds.vals()) {
      ExperimentalCycles.add<system>(cycles); 
      let result = await anActor.icrc79_confirm_subscription([{
        subscriptionId = subscriptionId;
        checkRate = null;
      }]);

      D.print(debug_show(("result: ", result)));
      
      results.add(result[0]);

    };
    return Buffer.toArray(results);
  };

  

};