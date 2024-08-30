import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type ConfirmResult = [] | [
  { 'Ok' : bigint } |
    { 'Err' : SubscriptionError }
];
export type ICRC16 = { 'Int' : bigint } |
  { 'Map' : Array<[string, ICRC16]> } |
  { 'Nat' : bigint } |
  { 'Set' : Array<ICRC16> } |
  { 'Nat16' : number } |
  { 'Nat32' : number } |
  { 'Nat64' : bigint } |
  { 'Blob' : Uint8Array | number[] } |
  { 'Bool' : boolean } |
  { 'Int8' : number } |
  { 'Ints' : Array<bigint> } |
  { 'Nat8' : number } |
  { 'Nats' : Array<bigint> } |
  { 'Text' : string } |
  { 'Bytes' : Uint8Array | number[] } |
  { 'Int16' : number } |
  { 'Int32' : number } |
  { 'Int64' : bigint } |
  { 'Option' : [] | [ICRC16] } |
  { 'Floats' : Array<number> } |
  { 'Float' : number } |
  { 'Principal' : Principal } |
  { 'Array' : Array<ICRC16> } |
  { 'ValueMap' : Array<[ICRC16, ICRC16]> } |
  {
    'Class' : Array<
      { 'value' : ICRC16, 'name' : string, 'immutable' : boolean }
    >
  };
export interface ICTokenSpec {
  'id' : [] | [bigint],
  'fee' : [] | [bigint],
  'decimals' : bigint,
  'canister' : Principal,
  'standard' : { 'ICRC1' : null } |
    { 'EXTFungible' : null } |
    { 'DIP20' : null } |
    { 'Other' : ICRC16 } |
    { 'Ledger' : null },
  'symbol' : string,
}
export interface KYCResult {
  'aml' : { 'NA' : null } |
    { 'Fail' : null } |
    { 'Pass' : null },
  'kyc' : { 'NA' : null } |
    { 'Fail' : null } |
    { 'Pass' : null },
  'token' : [] | [TokenSpec],
  'extensible' : [] | [ICRC16],
  'message' : [] | [string],
  'amount' : [] | [bigint],
  'timeout' : [] | [bigint],
}
export type SubscriptionError = { 'TokenNotFound' : null } |
  { 'InsufficientAllowance' : bigint } |
  { 'SubscriptionNotFound' : null } |
  { 'Duplicate' : null } |
  { 'InvalidDate' : null } |
  { 'Unauthorized' : null } |
  { 'ICRC17Error' : KYCResult } |
  { 'Other' : { 'code' : bigint, 'message' : string } } |
  { 'InvalidInterval' : null };
export interface Tester {
  'checksubscription' : ActorMethod<
    [Principal, Array<bigint>, bigint],
    Array<ConfirmResult>
  >,
}
export type TokenSpec = { 'IC' : ICTokenSpec } |
  { 'Extensible' : ICRC16 };
export interface _SERVICE extends Tester {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
