
module{

  

  public type MigrationFunction<T,A> = ((prevState: T, nextState: T, args: A, caller: Principal, getMigrationId: (T) -> Nat, upgrades : [(T, A, Principal) -> T]) -> T);

  
  public func migrate<T,A>() :  MigrationFunction<T,A>{

    let aFunc = func migrate(
      prevState: T, 
      nextState: T, 
      args: A,
      caller: Principal,
      getMigrationId: (T) -> Nat,
      upgrades : [(T, A, Principal) -> T]
    ): T {
      var state = prevState;
      
      var migrationId = getMigrationId(prevState);
      let nextMigrationId = getMigrationId(nextState);

      while (migrationId < nextMigrationId) {
        let migrate = upgrades[migrationId];
        migrationId :=  migrationId + 1;

        state := migrate(state, args, caller);
      };

      return state;
    };
    aFunc;
  };

};