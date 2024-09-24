import v0_1_0 "./v000_001_000/types";
import v0_2_0 "./v000_002_000/types";


module {
  // do not forget to change current migration when you add a new one
  // you should use this field to import types from you current migration anywhere in your project
  // instead of importing it from migration folder itself
  public let Current = v0_2_0;

  public type Args = ?v0_1_0.InitArgs;

  //change this current migration when you add a new one
  public let CurrentMigration = #v0_2_0;
  
  public let InitialMigration = #v0_0_0;

  public type State = {
    #v0_0_0: {#id; #data};
    #v0_1_0: {#id; #data:  v0_1_0.State};
    #v0_2_0: {#id; #data:  v0_2_0.State};
    // do not forget to add your new migration state types here
  };
};