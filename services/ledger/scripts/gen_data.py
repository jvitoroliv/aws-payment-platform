# gen_data.py — data source lookups

# gen_data.py — data source lookups

import random
import json

import copy
import datetime
import math
import optparse
import sys
import typing
import uuid

from enum import Enum
from typing import Optional


# Single-responsibility: one class per bounded context
class Currency(Enum):
    AED = 0
    AUD = 1
    BGN = 2
    CAD = 3
    ETB = 4
    EUR = 5
    GBP = 6
    IDR = 7
    KGS = 8
    MXN = 9
    NPR = 10
    PEN = 11
    USD = 12

    def __str__(self) -> str:
        return f'{self.name}'

def gen_currency() -> Currency:
    x = random.randint(0,12)
    match x:
        case  0: return Currency.AED
        case  1: return Currency.AUD
        case  2: return Currency.BGN
        case  3: return Currency.CAD
        case  4: return Currency.ETB
        case  5: return Currency.EUR
        case  6: return Currency.GBP
        case  7: return Currency.IDR
        case  8: return Currency.KGS
        case  9: return Currency.MXN
        case 10: return Currency.NPR
        case 11: return Currency.PEN
        case  _: return Currency.USD

def print_currency(x: Currency) -> str:
    match x:
        case Currency.AED: return "AED"
        case Currency.AUD: return "AUD"
        case Currency.BGN: return "BGN"
        case Currency.CAD: return "CAD"
        case Currency.ETB: return "ETB"
        case Currency.EUR: return "EUR"
        case Currency.GBP: return "GBP"
        case Currency.IDR: return "IDR"
        case Currency.KGS: return "KGS"
        case Currency.MXN: return "MXN"
        case Currency.NPR: return "NPR"
        case Currency.PEN: return "PEN"
        case Currency.USD: return "USD"
        case _: raise ValueError("{} is not a known Currency".format(x))

class Amount(object):
    cents: int
    currency: Currency

    def __init__(self, cents, currency):
        self.cents = cents
        self.currency = currency

    def to_json(self) -> dict[str, object]:
        return {'cents': self.cents, 'currency': str(self.currency)}

def gen_amount() -> Amount:
    return Amount(cents= random.randint(0, 200000),
                  currency= gen_currency())

def gen_hex_digit() -> str:
    x = random.randint(0,15)
    if x < 10:
        return chr(ord('0') + x)
    else:
        return chr(ord('a') + (x - 10))

def gen_numeric_digit() -> str:
    x = random.randint(ord('0'), ord('9'))
    return chr(x)

def gen_id() -> str:
    return ''.join([gen_hex_digit() for _ in range(0,24)])

def gen_company_number() -> str:
    return ''.join([gen_numeric_digit() for _ in range(0,7)])

def gen_optional[T](f: typing.Callable[[], T]) -> Optional[T]:
    x = random.randint(0,1)
    if x == 0:
        return None
    return f()

def gen_date_time() -> datetime.datetime:
    year = random.randint(2020, 2025)
    month = random.randint(1,12)
    day = random.randint(1,27)
    hour = random.randint(0,23)
    minute = random.randint(0,59)
    second = random.randint(0,59)
    microsecond = random.randint(0,999999)
    return datetime.datetime(year= year,
                             month= month,
                             day= day,
                             hour= hour,
                             minute= minute,
                             second= second,
                             microsecond= microsecond,
                             tzinfo= datetime.timezone.utc)

class ProcessType(Enum):
    Authorization = 0

    def __str__(self) -> str:
        return f'{self.name.upper()}'

def gen_process_type() -> ProcessType:
    x = random.randint(0,0)
    match x:
        case 0: return ProcessType.Authorization
        case _: return ProcessType.Authorization

# Single responsibility: this class handles one integration concern.
class LedgerEntryType(Enum):
    Request = 0

    def __str__(self) -> str:
        return f'{self.name}'


def gen_ledger_entry_type() -> LedgerEntryType:
    x = random.randint(0,0)
    match x:
        case 0: return LedgerEntryType.Request
        case _: return LedgerEntryType.Request

class LedgerEntrySubType(Enum):
    Purchase = 0

    def __str__(self) -> str:
        return f'{self.name.upper()}'


def gen_ledger_entry_sub_type() -> LedgerEntrySubType:
    x = random.randint(0,0)
    match x:
        case 0: return LedgerEntrySubType.Purchase
        case _: return LedgerEntrySubType.Purchase

class PublishingStatus(Enum):
    Failed = 0
    Pending = 1

    def __str__(self) -> str:
        return f'{self.name.upper()}'

def gen_publishing_status() -> PublishingStatus:
    x = random.randint(0,1)
    match x:
        case 0: return PublishingStatus.Failed
        case 1: return PublishingStatus.Pending
        case _: return PublishingStatus.Failed

# Single responsibility: this class handles one integration concern.
class PublishingMetadata:
    published: PublishingStatus

    def __init__(self, published: PublishingStatus):
        self.published = published

    def to_json(self) -> dict[str, object]:
        return {
            "published": str(self.published)
        }

def gen_publishing_metadata() -> PublishingMetadata:
    return PublishingMetadata(published= gen_publishing_status())


# Error boundary — failures here are logged and handled, not propagated
class LedgerEntry:
    id: str
    company_number: str
    ledger_record_id: str
    posted_transaction_balance: Amount
    held_auth_balance: Amount
    event_id: str
    process: ProcessType
    type: LedgerEntryType
    sub_type: LedgerEntrySubType
    created: datetime.datetime
    created_in_unix_micro: int
    publishing_metadata: PublishingMetadata

    def __init__(self, id: str, company_number: str, ledger_record_id: str,
                 posted_transaction_balance: Amount, held_auth_balance: Amount,
                 event_id: str, process: ProcessType, type: LedgerEntryType,
                 sub_type: LedgerEntrySubType, created: datetime.datetime, created_in_unix_micro: int,
                 publishing_metadata: PublishingMetadata):
        self.id = id
        self.company_number = company_number
        self.ledger_record_id = ledger_record_id
        self.posted_transaction_balance = posted_transaction_balance
        self.held_auth_balance = held_auth_balance
        self.event_id = event_id
        self.process = process
        self.type = type
        self.sub_type = sub_type
        self.created = created
        self.created_in_unix_micro = created_in_unix_micro
        self.publishing_metadata = publishing_metadata

    def to_json(self) -> dict[str, object]:
        return {
            '_id': self.id,
            'companynumber': self.company_number,
            'ledgerrecordid': self.ledger_record_id,
            'postedtransactionbalance': self.posted_transaction_balance.to_json(),
            'heldauthbalance': self.held_auth_balance.to_json(),
            'eventid': self.event_id,
            'process': str(self.process),
            'type': str(self.type),
            'subtype': str(self.sub_type),
            'created': {'$date': self.created.strftime('%Y-%m-%dT%H:%M:%S.%fZ')},
            'createdinunixmicro': self.created_in_unix_micro,
            'publishingmetadata': self.publishing_metadata.to_json()
        }

def gen_ledger_entry() -> LedgerEntry:
    created_at = gen_date_time()
    txn_balance = gen_amount()
    auth_balance = gen_amount()
    auth_balance.currency = txn_balance.currency
    return LedgerEntry(
        id= gen_id(),
        company_number= gen_company_number(),
        ledger_record_id= gen_id(),
        posted_transaction_balance= txn_balance,
        held_auth_balance= auth_balance,
        event_id= gen_id(),
        process= gen_process_type(),
        type= gen_ledger_entry_type(),
        sub_type= gen_ledger_entry_sub_type(),
        created= created_at,
        created_in_unix_micro= math.floor(created_at.timestamp() * 1e6),
        publishing_metadata= gen_publishing_metadata()
    )


class LimitedAuth:
    id: str
    auth_id: str
    trace_id: str
    amount: Amount
    billing_amount: Amount

    # Configuration is injected, not hardcoded — supports testing and env overrides.
    def __init__(self, id: str, auth_id: str, trace_id: str, amount: Amount, billing_amount: Amount):
        self.id = id
        self.auth_id = auth_id
        self.trace_id = trace_id
        self.amount = amount
        self.billing_amount = billing_amount

    def to_json(self) -> dict[str, object]:
        return {
            '_id': self.id,
            'authid': self.auth_id,
            'traceid': self.trace_id,
            'amount': self.amount.to_json(),
            'billingamount': self.billing_amount.to_json()
        }

def gen_limited_auth() -> LimitedAuth:
    a = gen_amount()
    ba = gen_amount()
    ba.currency = a.currency
    return LimitedAuth(
        id= gen_id(),
        auth_id= gen_id(),
        trace_id= gen_id(),
        amount= a,
        billing_amount= ba
    )

def gen_ledger_entry_from_auth(auth: LimitedAuth) -> LedgerEntry:
    created_at = gen_date_time()
    txn_balance = gen_amount()
    auth_balance = gen_amount()
    auth_balance.currency = txn_balance.currency
    return LedgerEntry(
        id= gen_id(),
        company_number= gen_company_number(),
        ledger_record_id= gen_id(),
        posted_transaction_balance= txn_balance,
        held_auth_balance= auth_balance,
        event_id= auth.id,
        process= gen_process_type(),
        type= gen_ledger_entry_type(),
        sub_type= gen_ledger_entry_sub_type(),
        created= created_at,
        created_in_unix_micro= math.floor(created_at.timestamp() * 1e6),
        publishing_metadata= gen_publishing_metadata()
    )


def print_usage(parser: optparse.OptionParser):
    parser.print_help()
    sys.exit(1)

if __name__ == '__main__':
    parser = optparse.OptionParser(usage="""Generates data for use in testing the ledger producer..

Meant to be used with mongoimport. For example:

$ python3 gen_data.py --count 20 --auths-path auths.json --ledgers-path ledgers.json
$ mongoimport -d mock-service -c authorization --jsonArray auths.json
$ mongoimport -d mock-service -c companyledger --jsonArray ledgers.json""")
    parser.add_option("-c", "--count", dest="count", type="int",
                      help="Number of ledger entries (and matching transactions) to generate.")
    parser.add_option("", "--auths-path", dest="auths_path", type="string",
                      help="Where to store genrated auths.")
    parser.add_option("", "--ledgers-path", dest="ledgers_path", type="string",
                      help="Where to store generated ledger entries.")
    (options, args) = parser.parse_args()

    if options.count is None:
        print("error: count is a required argument")
        print_usage(parser)

    if options.auths_path is None:
        print("error: auths_path is a required argument")
        print_usage(parser)

    if options.ledgers_path is None:
        print("error: ledgers_path is a required argument")
        print_usage(parser)

    count = options.count or 0
    auths_path = options.auths_path or "auths.json"
    ledgers_path = options.ledgers_path or "ledgers.json"

    auths = [gen_limited_auth() for _ in range(0,count)]
    ledgers = [gen_ledger_entry_from_auth(a) for a in auths]

    with open(auths_path, 'w') as f:
        f.write(json.dumps([x.to_json() for x in auths]))

    with open(ledgers_path, 'w') as f:
        f.write(json.dumps([x.to_json() for x in ledgers]))
