**Core in this checkout**

## What it is

Purchases records the amounts a company owes to, or has paid to, its vendors. It is the vendor-facing side of the product's [shared concepts](concepts.md): a vendor is the contact supplying goods or services, and a bill is the document that records the resulting amount owed.

A bill payment records settlement of that amount. A recurring bill represents a bill pattern that repeats over time. The [Bills Help Centre reference](https://akaunting.com/hc/docs/bills/) provides the source context for bills, vendors, payments, and recurring bills.

## Main capabilities

- A **vendor** is the vendor-side contact connected to purchase documents.
- A **bill** records an amount owed to a vendor for a purchase.
- A **bill payment** records settlement of the amount owed by a bill.
- A **recurring bill** represents a purchase bill that is expected to repeat.
- An **expense-side obligation** is the amount the company owes to a vendor, represented by the bill until it is settled by a bill payment.

Purchases is a product area in the [navigation menu reference](https://akaunting.com/hc/docs/the-user-interface/navigation-menu/); the [Bills Help Centre reference](https://akaunting.com/hc/docs/bills/) is the source for its document model.

## Related concepts

Invoices represent the customer-facing sales side; bills represent vendor-facing purchases. The principal purchases relationship is vendor -> bill -> bill payment, while a recurring bill represents a repeating bill relationship. The shared meanings of contact, document, and payment are defined in [concepts](concepts.md).

See [sales](sales.md) for the customer-facing counterpart. [Banking](banking.md) explains the transaction connection when a bill payment has a banking counterpart, and [reporting](reporting.md) analyzes purchase records and their resulting activity. These relationships align with the [Bills Help Centre reference](https://akaunting.com/hc/docs/bills/).

## Sources

- [Bills](https://akaunting.com/hc/docs/bills/), checked as part of the Help Centre snapshot on 2026-08-06.
- [Navigation menu](https://akaunting.com/hc/docs/the-user-interface/navigation-menu/).
