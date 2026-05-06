# shopee-research

Search and research products on Shopee Thailand (shopee.co.th).

## Components

- **product-listing** skill — search Shopee for products with optional filters, then generate an HTML report in Thai

## Setup

No environment variables required. The skill uses Claude in Chrome browser tools to render Shopee's JavaScript-heavy pages — the Chrome extension must be connected before using this plugin.

## Usage

Trigger the `product-listing` skill by asking Claude to:

- "Search for [product] on Shopee"
- "Find [product] on shopee.co.th"
- "Look up prices for [product] on Shopee"

Claude will ask about optional filters (result count, shop type, delivery speed) before searching.

Results are saved as an HTML report in `./shopee_reports/` named `{YYYY}-{MM}-{DD}-{HHMM}.html`.
