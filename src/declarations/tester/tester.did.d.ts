import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';
import type { IDL } from '@dfinity/candid';

export type ConfirmResult = [] | [
  { 'Ok' : bigint } |
    { 'Err' : SubscriptionError }
];
export type SubscriptionError = { 'TokenNotFound' : null } |
  { 'InsufficientAllowance' : bigint } |
  { 'SubscriptionNotFound' : null } |
  { 'Duplicate' : null } |
  { 'FoundActiveSubscription' : bigint } |
  { 'InsufficientBalance' : bigint } |
  { 'InvalidDate' : null } |
  { 'Unauthorized' : null } |
  { 'Other' : { 'code' : bigint, 'message' : string } } |
  { 'InvalidInterval' : null };
export interface Tester {
  'checksubscription' : ActorMethod<
    [Principal, Array<bigint>, bigint],
    Array<ConfirmResult>
  >,
}
export interface _SERVICE extends Tester {}
export declare const idlFactory: IDL.InterfaceFactory;
export declare const init: (args: { IDL: typeof IDL }) => IDL.Type[];
