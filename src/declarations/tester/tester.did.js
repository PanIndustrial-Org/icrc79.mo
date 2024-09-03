export const idlFactory = ({ IDL }) => {
  const SubscriptionError = IDL.Variant({
    'TokenNotFound' : IDL.Null,
    'InsufficientAllowance' : IDL.Nat,
    'SubscriptionNotFound' : IDL.Null,
    'Duplicate' : IDL.Null,
    'FoundActiveSubscription' : IDL.Nat,
    'InvalidDate' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'Other' : IDL.Record({ 'code' : IDL.Nat, 'message' : IDL.Text }),
    'InvalidInterval' : IDL.Null,
  });
  const ConfirmResult = IDL.Opt(
    IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : SubscriptionError })
  );
  const Tester = IDL.Service({
    'checksubscription' : IDL.Func(
        [IDL.Principal, IDL.Vec(IDL.Nat), IDL.Nat],
        [IDL.Vec(ConfirmResult)],
        [],
      ),
  });
  return Tester;
};
export const init = ({ IDL }) => { return []; };
