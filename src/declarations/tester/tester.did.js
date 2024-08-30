export const idlFactory = ({ IDL }) => {
  const ICRC16 = IDL.Rec();
  ICRC16.fill(
    IDL.Variant({
      'Int' : IDL.Int,
      'Map' : IDL.Vec(IDL.Tuple(IDL.Text, ICRC16)),
      'Nat' : IDL.Nat,
      'Set' : IDL.Vec(ICRC16),
      'Nat16' : IDL.Nat16,
      'Nat32' : IDL.Nat32,
      'Nat64' : IDL.Nat64,
      'Blob' : IDL.Vec(IDL.Nat8),
      'Bool' : IDL.Bool,
      'Int8' : IDL.Int8,
      'Ints' : IDL.Vec(IDL.Int),
      'Nat8' : IDL.Nat8,
      'Nats' : IDL.Vec(IDL.Nat),
      'Text' : IDL.Text,
      'Bytes' : IDL.Vec(IDL.Nat8),
      'Int16' : IDL.Int16,
      'Int32' : IDL.Int32,
      'Int64' : IDL.Int64,
      'Option' : IDL.Opt(ICRC16),
      'Floats' : IDL.Vec(IDL.Float64),
      'Float' : IDL.Float64,
      'Principal' : IDL.Principal,
      'Array' : IDL.Vec(ICRC16),
      'ValueMap' : IDL.Vec(IDL.Tuple(ICRC16, ICRC16)),
      'Class' : IDL.Vec(
        IDL.Record({
          'value' : ICRC16,
          'name' : IDL.Text,
          'immutable' : IDL.Bool,
        })
      ),
    })
  );
  const ICTokenSpec = IDL.Record({
    'id' : IDL.Opt(IDL.Nat),
    'fee' : IDL.Opt(IDL.Nat),
    'decimals' : IDL.Nat,
    'canister' : IDL.Principal,
    'standard' : IDL.Variant({
      'ICRC1' : IDL.Null,
      'EXTFungible' : IDL.Null,
      'DIP20' : IDL.Null,
      'Other' : ICRC16,
      'Ledger' : IDL.Null,
    }),
    'symbol' : IDL.Text,
  });
  const TokenSpec = IDL.Variant({ 'IC' : ICTokenSpec, 'Extensible' : ICRC16 });
  const KYCResult = IDL.Record({
    'aml' : IDL.Variant({
      'NA' : IDL.Null,
      'Fail' : IDL.Null,
      'Pass' : IDL.Null,
    }),
    'kyc' : IDL.Variant({
      'NA' : IDL.Null,
      'Fail' : IDL.Null,
      'Pass' : IDL.Null,
    }),
    'token' : IDL.Opt(TokenSpec),
    'extensible' : IDL.Opt(ICRC16),
    'message' : IDL.Opt(IDL.Text),
    'amount' : IDL.Opt(IDL.Nat),
    'timeout' : IDL.Opt(IDL.Nat),
  });
  const SubscriptionError = IDL.Variant({
    'TokenNotFound' : IDL.Null,
    'InsufficientAllowance' : IDL.Nat,
    'SubscriptionNotFound' : IDL.Null,
    'Duplicate' : IDL.Null,
    'InvalidDate' : IDL.Null,
    'Unauthorized' : IDL.Null,
    'ICRC17Error' : KYCResult,
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
