---
name: product-listing
description: >
  This skill should be used when the user wants to "search for a product on Shopee",
  "find something to buy on Shopee", "look up prices on Shopee", "research products
  on shopee.co.th", or is looking for an item to buy online and wants Shopee results.
  Supports filtering by price range, shop type (Official Mall, Preferred), and
  delivery speed.
---

## Search URL

```
https://shopee.co.th/search?keyword={product-keyword}&sortBy=sales&fe_filter_options=....
```

The `sortBy=sales` is very important as the result pages will include +monthly
sales+ data.

## URL query filter format

Below are pretty JSON representation of the query param for the search filter.
Actual search filter param will be URL encoded and compacted (no whitespace).

```
fe_filter_options=[
    {
        "group_name": "<filter-name>",
        "values": ["<value1>", "<value2>", ...]
    }
]
```

Filters:
  - shop type - types of the sellers. Default is including all shops
    filter-name: SHOP_TYPE
    value:       'OFFICIAL_MALL' or 'PREFERRED'

  - delivery options (ส่งด่วน)
    filter-name: SHIPPING_OPTIONS_V2
    value:       INSTANT_DELIVERY


### Step 1: Inform a user for available search options

Inform a user for available search options for general things like how many
products a user wants to be included in the result. Default is 30, or how fast
a user wants a product delivered, e.g. < 2 days, within the same day, tomorrow, etc., the shop type.

### Step 2: Open Shopee in a real browser tab and fetch the search results

**IMPORTANT: Always use the Claude in Chrome browser tools for this step — never use WebFetch or any raw HTTP tool. Shopee requires a real browser session with JavaScript rendering and cookies.**

1. Call `tabs_context_mcp` (with `createIfEmpty: true`) to get or create a browser tab group.
2. Call `tabs_create_mcp` to open a fresh tab in that group.
3. Build the full search URL with the keyword and any filter params, then call `navigate` with that URL and the tab ID from step 2.
4. Wait briefly for Shopee's JavaScript to finish rendering the product grid: call `computer` with action `wait` and duration `3`.
5. Call `computer` with action `screenshot` to verify the page loaded correctly and check for any CAPTCHA or login wall:
   - If a CAPTCHA appears: show the screenshot to the user and ask them to solve it in the browser before continuing.
   - If a login/region prompt appears: dismiss it via `computer` click or scroll past it.
6. Call `get_page_text` on the tab to extract all visible product text. If the product grid hasn't fully loaded, wait 2 more seconds and try `read_page` instead to get the accessibility tree — it often contains product data even before full render.
7. If results look incomplete (fewer products than expected), scroll down with `computer` (action `scroll`, direction `down`, scroll_amount `5`) one or two times to trigger lazy-loaded products, then call `get_page_text` again.
8. Call `tabs_close_mcp` on the tab after data is extracted.

### Step 3: Report

Compile and create an HTML report including the same information you find on
Shopee. If available, include these information:

- Product image
- link to the product page when clicking on the product name
- monthly sales (ex. 147 items / month)
- shop type (ex. ร้านค้าแนะนำ, shopee mall)

Put the report into `./shopee_reports/` folder. The report name will be
in this format, `{YYYY}-{MM}-{DD}-{HHMM}.html`. Use 24hr time.
IMPORTANT: The report will be in Thai language.
