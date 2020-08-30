# Magento Ruby library

## Install

Add in your Gemfile

```rb
gem 'magento', '~> 0.7.0'
```

or run

```sh
gem install magento
```

### Setup

```rb
Magento.url   = 'https://yourstore.com'
Magento.token = 'MAGENTO_API_KEY'
Magento.store = :default # optional, Default is :all

Magento.with_config(store: :other_store) do # accepts store, url and token parameters
  Magento::Product.find('sku')
end
```

## Models
```rb
Magento::Product
Magento::Order
Magento::Country
Magento::Category
```

## Get details

```rb
Magento::Product.find('sku-test')
Magento::Order.find(25)
Magento::Country.find('BR')
```
\* _same pattern to all models_

**Outside pattern**

Get customer by token

```rb
Magento::Customer.find_by_token('user_token')
```

## Get List

```rb
Magento::Product.all
```

#### Select fields:
```rb
Magento::Product.select(:id, :sku, :name).all
Magento::Product.select(:id, :sku, :name, extension_attributes: :category_links).all
Magento::Product.select(:id, :sku, :name, extension_attributes: [:category_links, :website_ids]).all
Magento::Product.select(:id, :sku, :name, extension_attributes: [:website_ids, { category_links: :category_id }]).all
```

#### Filters:

```rb
Magento::Product.where(name_like: 'IPhone%').all
Magento::Product.where(price_gt: 100).all

# price > 10 AND price < 20
Magento::Product.where(price_gt: 10)
                .where(price_lt: 20).all

# price < 1 OR price > 100
Magento::Product.where(price_lt: 1, price_gt: 100).all

Magento::Order.where(status_in: [:canceled, :complete]).all
```

| Condition | Notes |
| --------- | ----- |
|eq         | Equals. |
|finset     | A value within a set of values |
|from       | The beginning of a range. Must be used with to |
|gt         | Greater than |
|gteq       | Greater than or equal |
|in         | In. The value is an array |
|like       | Like. The value can contain the SQL wildcard characters when like is specified. |
|lt         | Less than |
|lteq       | Less than or equal |
|moreq      | More or equal |
|neq        | Not equal |
|nfinset    | A value that is not within a set of values |
|nin        | Not in. The value is an array |
|notnull    | Not null |
|null       | Null |
|to         | The end of a range. Must be used with from |


#### SortOrder:

```rb
Magento::Product.order(:sku).all
Magento::Product.order(sku: :desc).all
Magento::Product.order(status: :desc, name: :asc).all
```

#### Pagination:

```rb
# Set page and quantity per page
Magento::Product.page(1)       # Current page, Default is 1
                .page_size(25) # Default is 50
                .all

# per is an alias to page_size
Magento::Product.per(25).all
```

#### Example of several options together:
```rb
products = Magento::Product.select(:sku, :name)
                           .where(name_like: 'biscoito%')
                           .page(1)
                           .page_size(5)
                           .all
```

\* _same pattern to all models_

### Response

The `all` method retorns a `Magento::RecordCollection` instance

```rb
products.first
>> <Magento::Product @sku="2100", @name="Biscoito Piraque Salgadinho 100G">

products[0]
>> <Magento::Product @sku="2100", @name="Biscoito Piraque Salgadinho 100G">

products.last
>> <Magento::Product @sku="964", @name="Biscoito Negresco 140 G Original">

products.map(&:sku)
>> ["2100", "792", "836", "913", "964"]

products.size
>> 5

products.current_page
>> 1

products.next_page
>> 2

products.last_page?
>> false

products.page_size
>> 5

products.total_count
>> 307

products.filter_groups
>> [<Magento::FilterGroup @filters=[<Magento::Filter @field="name", @value="biscoito%", @condition_type="like">]>]
```

All Methods:

```rb
# Information about search criteria
:current_page
:next_page
:last_page?
:page_size
:total_count
:filter_groups

# Iterating with the list of items
:count
:length
:size

:first
:last
:[]
:find

:each
:each_with_index
:sample

:map
:select
:filter
:reject
:collect
:take
:take_while

:sort
:sort_by
:reverse_each
:reverse

:all?
:any?
:none?
:one?
:empty?
```

## Create

```rb
Magento::Order.create(
  customer_firstname: '',
  customer_lastname: '',
  customer_email: '',
  # others attrbutes ...,
  items: [
    {
      sku: '',
      price: '',
      qty_ordered: 1,
      # others attrbutes ...,
    }
  ],
  billing_address: {
    # attrbutes...
  },
  payment: {
    # attrbutes...
  },
  extension_attributes: {
    # attrbutes...
  }
)
```

### Update

```rb
product = Magento::Product.find('sku-teste')

product.name = 'Updated name'
product.save

# or

product.update(name: 'Updated name')
```

### Delete

```rb
product = Magento::Product.find('sku-teste')

product.delete

# or

Magento::Product.delete('sku-teste')
```

## GuestCart

Set payment information to finish the order
```rb
cart = Magento::GuestCart.find('gXsepZcgJbY8RCJXgGioKOO9iBCR20r7')

# or use "build" to not request information from the magento API
cart = Magento::GuestCart.build(
  cart_id: 'aj8oUtY1Qi44Fror6UWVN7ftX1idbBKN'
)

cart.payment_information(
  email: 'customer@gmail.com',
  payment: { method: 'cashondelivery' }
)

>> "234575" # return the order id
```

## Invoice an Order

```rb
Magento::Order.invoice(order_id)
>> 25 # return incoice id

# or from instance

order = Magento::Order.find(order_id)

invoice_id = order.invoice

# you can pass parameters too

invoice_id = order.invoice(
  capture: false,
  appendComment: true,
  items: [{ order_item_id: 123, qty: 1 }], # pass items to partial invoice
  comment: {
    extension_attributes: { },
    comment: "string",
    is_visible_on_front: 0
  },
  notify: true
)
```

[Complete Invoice Documentation](https://magento.redoc.ly/2.4-admin/tag/orderorderIdinvoice#operation/salesInvoiceOrderV1ExecutePost)

## Create refund for invoice

```rb
Magento::Invoice.invoice(refund_id)
>> 12 # return refund id

# or from instance

invoice = Magento::Invoice.find(invoice_id)

refund_id = invoice.refund

# you can pass parameters too

invoice.refund(
  items: [
    {
      extension_attributes: {},
      order_item_id: 0,
      qty: 0
    }
  ],
  isOnline: true,
  notify: true,
  appendComment: true,
  comment: {
    extension_attributes: {},
    comment: string,
    is_visible_on_front: 0
  },
  arguments: {
    shipping_amount: 0,
    adjustment_positive: 0,
    adjustment_negative: 0,
    extension_attributes: {
      return_to_stock_items: [0]
    }
  }
)
```

[Complete Refund Documentation](https://magento.redoc.ly/2.4-admin/tag/invoicescomments#operation/salesRefundInvoiceV1ExecutePost)


## Other Invoice methods

```rb
invoice = Magento::Invoice.find(invoice_id)

invoice.capture # or
Magento::Invoice.capture(invoice_id)

invoice.void # or
Magento::Invoice.void(invoice_id)

invoice.send_email # or
Magento::Invoice.send_email(invoice_id)

Magento::Invoice.comments(invoice_id).all
Magento::Invoice.comments(invoice_id).where(created_at_gt: Date.today.prev_day).all
```

## Creates new Shipment for given Order.

```rb
Magento::Order.ship(order_id)
>> 25 # return shipment id

# or from instance

order = Magento::Order.find(order_id)

order.ship

# you can pass parameters too

order.ship(
  capture: false,
  appendComment: true,
  items: [{ order_item_id: 123, qty: 1 }], # pass items to partial shipment
  tracks: [
    {
      extension_attributes: { },
      track_number: "string",
      title: "string",
      carrier_code: "string"
    }
  ]
  notify: true
)
```

[Complete Shipment Documentation](https://magento.redoc.ly/2.4-admin/tag/orderorderIdship#operation/salesShipOrderV1ExecutePost)

___

##TODO:

### Search products
```rb
Magento::Product.search('tshort')
```

### First result
```rb
Magento::Product.first
>> <Magento::Product @sku="some-sku" ...>

Magento::Product.where(name_like: 'some name%').first
>> <Magento::Product @sku="some-sku" ...>
```

### Last result
```rb
Magento::Product.last
>> <Magento::Product @sku="some-sku" ...>

Magento::Product.where(name_like: 'some name%').last
>> <Magento::Product @sku="some-sku" ...>
```

### Count result
```rb
Magento::Product.count
>> 7855
Magento::Product.where(name_like: 'some name%').count
>> 15
```

### Tests