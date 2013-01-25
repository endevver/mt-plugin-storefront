# Overview

The Store Front plugin for Movable Type adds the ability for administrators 
to define for use on their web site a collection of products which can be sold
through a selection of payment processors, like PayPal or Google Checkout for 
the express purpose of allowing users to assemble a digital store front, or
put a "pay wall" in front of select pieces of content quickly and easily 
using Movable Type or Melody. 

# Prerequisites

Store Front is currently compatible with Movable Type 4 only.

## Config Assistant

This plugin requires the Config Assistant plugin. Movable Type users
will need to install this plugin separately from the URL below.
Users of the Melody publishing system already have Config Assistant
installed.

Download Config Assistant: http://bit.ly/89xYtz (MT Users only)

## Business PayPal Account

Currently the only payment gateway supported is PayPal. To accept payments
through PayPal, you will need to go to PayPal's web site an upgrade an
existing account or register a new Business Account. 

# Installation

To install this plugin follow the instructions found here:

http://tinyurl.com/easy-plugin-install

## Features

* Create and manage products for sale on your web site.
* Manage subscriptions and recurring payments to access a service or content.
* Generate "Buy Now" buttons on your web site using simple template tags.
* View a list of subscribers or purchasers from which to generate reports.
* Track payments associated with recurring payments.
* Notify administrators via email when new purchases have been made.

## Who is this plugin for?

This plugin was created and designed with the following use cases in mind:

* Give administrators the ability to sell physical merchandise, or to manage 
  inventory or availability of an item through their blog. In this scenario, 
  a user of the plugin maintains inventory of a product of some kind. They 
  enter the system, create a product, associate with that product the number 
  of items they have in their inventory, and then publish to their web site 
  a page that contains a "Buy Now" button to purchase that item. Once 
  complete, the plugin will route all purchases through a payment system to 
  purchase the item. Once purchased, the plugin will decrease the inventory 
  accordingly and then send emails to interested parties to confirm and 
  notify them about the transaction.

* Allow bloggers to offer premium access to their blog on a subscription basis,
  also known as a "pay wall." In this scenario, a user of this plugin would 
  define a product that requires a recurring payment. They would then publish 
  a "Subscribe Now" button on their web site, that when clicked would take a 
  user through a payment processor to purchase the subscription. The user of 
  the plugin would then augment their templates to evaluate whether or not a 
  user has purchased a specific subscription and display content (or not 
  display content) accordingly.

It is important to note that the plugin itself assigns no meaning to any of
the products that are created by users of the plugin, nor is the plugin able 
to enforce access control automatically. In order to setup a successful
e-commerce site, users of this plugin must edit their templates to:

1. Surface appropriate payment buttons for products and subscriptions.

2. Enforce access control to premium content.

And of course...

* Package and ship physical merchandise this plugin facilitates the purchase 
  of.

# Setup

All settings can be found and modified at the location found by following 
these instructions:

* Navigate to System Overview > Plugins. Find Store Front in the list of
  installed plugins and click it. Click on the settings tab to reveal all
  of the configuration options for the plugin.

## Sandbox Mode

During development it is advisable to set the plugin to run in "Sandbox"
mode. This will force the entire plugin to route all purchase requests 
through your payment gateway's sandbox/test interfaces. This will prevent
credit cards from being charged, but will in all other ways simulate the
behavior of the system you are designing.

## Landing Pages

Two pages should be constructed within your installation to which buyers
will be directed to upon successfully purchasing a product, or when they 
cancel the purchase process. Publish these two pages and take note of their
respective URLs.

Navigate to the plugin's setting page (see above), find the following 
fields and enter in the URLs from above:

* Purchase Success URL
* Purchase Cancel URL

## PayPal

In order to accept payments, users will first need to acquire a PayPal 
Business Account.

## Encrypted PayPal Payment Buttons

If you wish to encrypt the payment buttons you publish on your web site,
which is recommended to prevent fraud, then you will need to take extra
steps to secure your system and setup PayPal. 

### OpenSSL

To encrypt payment buttons you will need the latest, most secure version
of OpenSSL installed on your server. This is an open source, freely
available piece of software available for most platforms. Most unix 
installations already have OpenSSL installed. 

Take note of where OpenSSL is installed on your system. The Store Front
plugin will attempt to find its installation path automatically (if the
File::Which module is installed). If it is not installed, then you will
need to enter in the path to OpenSSL manually on the plugin's settings
page.

### Certification Generation

You will need to generate two important files using OpenSSL once it is
installed:

* a private key
* a public certificate

Once these have been created, you will need to upload your public 
certificate into PayPal and make note of the certificate ID assigned
to your certificate. 

Finally you will need to download PayPal's public certificate they make
available to you.

Keep all three of these files handy, and then upload them into the 
Store Front plugin via the plugin's settings area.

This can be an intimidating process for people not comfortable working
via the command line, but PayPal has provided excellent instructions 
on this process at the URL below. Read and follow them carefully. If
you need help, contact a trusted Movable Type contractor to assist.

* [Securing Your Website Payments Standard Buttons](http://bit.ly/9Rpm5G)

**Example Certificate and Key File**

The files you generate, and the file you will download from PayPal are 
all simple text files. They all look similar to the following:

    -----BEGIN CERTIFICATE-----
    MIIDoTCCAwqgAwIBAgIBADANBgkqhkiG9w0BAQUFADCBmDELMAkGA1UEBhMCVVMx
    EzARBgNVBAgTCkNhbGlmb3JuaWExETAPBgNVBAcTCFNhbiBKb3NlMRUwEwYDVQQK
    EwxQYXlQYWwsIEluYy4xFjAUBgNVBAsUDXNhbmRib3hfY2VydHMxFDASBgNVBAMU
    ...snip...
    P/dwdXwficf+rlG+0V9GBPJZYKZJQ069W/ZRkUuWFQ+Opd2yhPpneGezmw3aU222
    CGrdKhOrBJRRcpoO3FjHHmXWkqgbQqDWdG7S+/l8n1QfDPp+jpULOrcnGEUY41Im
    jZJTylbJQ1b5PBBjGiP0PpK48cdF
    -----END CERTIFICATE-----

### IPN Notification URL

You do not need to specify the URL to which IPN notifications will be sent.
This information will be provided to PayPal automatically via the payment
button generated by the system.

# Usage

In the following section we will review how exactly this plugin works, and
how it can be employed to accomplish specific tasks.

## Products Explained

A "product" in the Store Front plugin refers to an item of some kind that
a user can purchase through the system. Products consist of the following 
properties:

* **SKU**: A unique ID you assign to the product. This may often refer to an
  identifier coming from a system external to Movable Type. This field may then
  help to correlate purchases to an internal tracking scheme.

* **Name**: The short name for the product. (required)

* **Description**: A longer, more descriptive summary of the product. 
  (optional)

* **List Price**: This is the list price of the item. (required)

* **Sale Price**: This is the sale price for the item. If specified, this
  is the price the consumer will pay when purchasing the product. (this is
  used for one-time payment products only)

* **Inventory**: The number of items on hand to sell. While a user is free
  to enter in any value for this property, they should keep in mind that
  the system may also be modifying this properties value as purchases are
  processed. A user can enter a specific value or select "unlimitted" to 
  indicate that their is no limit to the number of purchases that can be 
  made. 

* **Payment Type**: The system supports two kinds of payments: a "one 
  time transaction" and a "subscription." A one time transaction should
  be assigned to those products that can outright purchased, while a
  subscription should be assigned to those products which refer to goods
  and services that are bound to items for which access is contingent upon
  having a valid and up-to-date subscription.

* **Status**: Products should rarely be deleted from the system, especially
  after a purchase of that product has been made. Instead, a product's status
  should be changed to reflect its availability. Allowable values are:

  * out of stock
  * discontinued
  * available/active
  * pre-order only

  *These statuses are customizable by the system administrator from the plugin's
  settings area.*

* **Limit Quantity** You can limit customers to one item per order. This is
  especially advisable for subscriptions, but may also apply to other purchases.
  If this box is unchecked, then the customer will be allowed to modify the
  quantity they will order prior to paying.

### Additional Subscription fields

Subscriptions are a slightly more complex product in that they require users
to enter in more data in order to properly inform the purchasing system on the 
payment schedule for the product. These fields are:

* **Period**: The billing frequency for the subscription. Acceptable values
  are: weekly, bi-weekly, monthly, quarterly, and yearly.

* **Start Date**: A duration relative to the purchase date indicating when
  billing should start. For example, you may want to give users a 15 day free
  trial, and automatically begin charging their credit card at the end of 
  the trial.

* **Recurrence:**: The number of times a client should be billing on a 
  recurring basis. This is good for establishing a one year subscription billed
  monthly for example. 

### Additional field for taxes and shipping

* **Tax Rate**: You can apply an individual tax rate to each product in your
  catalog allowing you tax select items and at different rates. 

* **Shipping Cost**: You can enter in a flat shipping rate for the item. If
  provided this will be added to the cost of the buyer's order, if the payment
  gateway supports the specification of shipping costs (PayPal does).

* **Weight**: You can enter in the weight of the item, which can be used as
  an alternative to a fixed rate shipping cost. If the payment gateway supports
  the specification of this data (PayPal does), then it will sum the total 
  weight of the order to compute address specific shipping costs.

## Creating Products

To create a product, select "Product" under the "Create" item in the top navbar.  
You will be prompted to enter the various properties and the payment type of the
product being created. 

Whether you are selling merchandise or a subscription, all products are 
considered to be assets in the Movable Type system and are therefore not 
necessarily bound to a published entry. Hence, the mere creation of a product 
does not *necessarily* result in the product being visible on the main web site.  
The visibility of a product depends upon the nature and requirements of the 
theme being used by the web site in question.

## Managing and Editing Products

Once a product has been created it can be viewed and edited from one of two
places. First, because a product is an asset, it can be viewed in the list of
all assets in the system found under the Manage > Assets area. However, because
products exhibit unique properties and characteristics, a more specialized 
listing and management screen has been provided to make management easier. 
This screen can be accessed under the Manage > Products area. 

*It should be noted that because all products are assets, products may also 
managed from the Manage > Assets screen as well. However, the default "Edit
Asset" screen does not permit the editing of all meta data fields associated
with an asset.*

On this listing screen administrators will be able to see a paginated list of 
all products in the system, the number of purchasers of the product, available 
inventory, and other vital statistics. Administrators will also be able to 
easily view a list of related payments and purchases for any product listed.

## Payment Types: One-time Transactions and Subscriptions

While creating a product you will elect to create a product that is purchased
through a single transaction, or one that is based upon a recurring payment or
subscription. 

## Managing Subscriptions

Products that utilize a recurring payment system will automatically have 
associated with them a "subscription" for each and every purchase that is made.
A subscription then provides the basis for which administrators can inspect the
status of a user's access to the system, can view related payments, and take
other important actions as they relate to the customer's account.

The status of a subscription can vary depending upon the client's payment
history and last payment. A subscription's status can be one of the following:

* active - appears for all active and up to date subscriptions.
* cancelled - appears when the buyer or seller cancels the subscription.
* expired - appears when the duration for the subscription is valid has passed.
* pending - 
* in process - this is a transient status that appears when a payment notification
  for a subscription has been received, but not a "create subscription" 
  notification has been received. 

To access a list of subscriptions, click the "Manage Subscriptions" menu item found
under the main "Store" menu. On the resulting screen you will be able to view
a list of recent new subscriptions that have been made. From there, 
administrators will also be able to filter subscriptions by their status and
other criteria.

## Managing and Viewing Payments

To view a history of all payments that have been received click on the 
"Manage Payments" item under the main "Store" menu. From here administrators will 
be able to search for a payment by reference number and be able to take simple
actions as they relate to a payment, e.g. refund payment, etc.

# Template Tags

The following reference details the template tags provided by this plugin.

## Accessing a Product's Meta Data

All of a product's properties, its price, etc, can be accessed through template
tags available to all Movable Type users. The template tag to use is the 
`<$mt:AssetProperty$>` tag. For example:

    <$mt:AssetProperty property="PROPERTY_NAME"$>

Here is a list of all of a product's property names:

* `sku_id` (string)
* `inventory_type` (integer)
* `inventory` (integer)
* `payment_type` (integer)
* `status` (string)

**Shipping Properties**

* `requires_shipping` (integer)
* `weight` (float)
* `weight_unit` (string)
* `shipping_cost` (float)

**One Time Purchase Options**

* `list_price` (float)
* `sale_price` (float)
* `tax_rate` (float)
* `limit_per_order` (integer)

**Subscription Options**

* `offer_trial` (integer)
* `trial_price` (float)
* `trial_duration` (integer)
* `trial_duration_units` (string)
* `duration` (integer)
* `duration_units` (string)
* `recur` (integer)
* `recurrence_count` (integer)

The product's name and description can be displayed using the following tags
respectively:

* `<$mt:AssetLabel$>`
* `<$mt:AssetDescription$>`

## Function Tags

The following template tags are provided to you by the Store Front plugin:

### `<$mt:PayPalButton$>`

**Arguments**

* `encrypt` (boolean) - When set to true, the button generated will be 
  encrypted to help prevent fraud. This is the recommended setting for
  production usage. In development however, it will be useful to leave this
  as false so that you can manually inspect the properties of the button.
  Default: false.

* `require_login` (boolean) - When set to true, a link to an internal app
  page will be generated through which a user will be required to first login.
  The resulting button that is generated (and submitted automatically by the
  plugin) will be encoded with the authenticated user's user id so that the
  purchase can be correlated to their account. When false, this will result
  in the tag outputting the raw purchase button and no user information will
  correlated to the purchase. Default: false.

* `auto_submit` (boolean) - When this is set to true, the submit button for the
  form generated will be suppressed, allowing for an invisible button to be 
  generated and submitted automatically. This is used primarily internally by 
  the plugin. Default: false.

## Block Tags

### `<mt:DoesUserHaveActiveSubscription>`

> **Maybe: `<mt:UserIsAuthorized>`??**

### `<mt:HasUserPurchased>` 

> **Maybe: `<mt:ProductIfPurchased>`??**

### `<mt:IsProductOnSale>` 

> **Maybe: `<mt:ProductHasDiscount>`??**

# Designer Guide

Designers have the unique challenge of integrating with this plugin's 
functionality, and because this plugin assigns no inherent meaning to what can
be purchased or subscribed to, it is up to them in order to establish that
meaning through the web sites and store fronts they build.

To assist designers in wrapping their head around the intended ways in which
this plugin can be deployed, the following guides have been written in support
of the most common use cases supported by this plugin. They are:

* Building a store front to sell physical merchandise.
* Selling access to the full version of a blog entry.
* Allowing users to subscribe to premium content on a web site.

## Building a Store Front, Selling Merchandise

Let's suppose you wanted to build a web site through which you want to sell 
t-shirts. For this implementation we recommend the use of Movable Type Pro and
custom fields. Here is how you would go about it:

1. **Create your blog**

  Login to Movable Type and create a new blog. This "blog" you are creating will
  be a repository for each of the t-shirts styles you are selling, with one
  blog entry per t-shirt style you want to sell.

2. **Create your custom fields**

  Next, you will need to define a number of custom fields that will be made
  available on each entry page. The fields you use will depend largely upon the
  design you have chosen for your store front, but generally speaking you will
  probably need at least the following custom fields:
  
  * Product Image - a field into which you can upload a picture of the t-shirt.

  * Product (small), Product (medium), Product (large), Product (x-large) -
    three fields which you will associate with the product/inventory you have 
    on hand for size small, medium, large and extra-large t-shirts respectively.
    
    This approach is necessary because for t-shirts, you will need to manage
    the inventory you have on hand for small t-shirts independently from any 
    other size. For example, it is entirely possible for you to run out of 
    large t-shirts well before running out of another size. There you create 
    a product/SKU for each size, and only one "blog entry" through which you
    sell each of the sizes available.

  That's it. Once these associations have been made, you will be able to display 
  a wealth of data that relates to each of the items you are selling in your 
  catalog on the website. 

3. **Build out your templates**

  With the data model complete, you can now bring to bear all of Movable Type's
  templating tags, as well as the ones provided by this plugin to render your
  entire t-shirt catalog. Let's look at a simple template tag recipe that
  may come in handy during your production:
  
          <mt:setvartemplate name="product_details">
            <$mt:AssetLabel$><br />
            <$mt:BuyButton$><br />
            <mt:if tag="ProductInventory" eq="0">
              <$mt:ProductInventory$> available
            <mt:else tag="ProductInventory" eq="1">
              Only one left!
            <mt:else>
              Sorry, out of stock.
            </mt:if>
          </mt:setvartemplate>
          <h1><$mt:EntryTitle$></h1>
          <h2>Description</h2>
          <img src="<$mt:ProductImageURL$>" align="left" />
          <$mt:EntryBody$>
          <h2>Buy Now</h2>
          <mt:AssetTShirtSmall>
            <$mt:var name="product_details"$>
          </mt:AssetTShirtSmall>
          <mt:AssetTShirtMedium>
            <$mt:var name="product_details"$>
          </mt:AssetTShirtMedium>
          <mt:AssetTShirtLarge>
            <$mt:var name="product_details"$>
          </mt:AssetTShirtLarge>

  This recipe will display the name and an image of the t-shirt you are selling.
  Then for each size available, it will display a buy now button and the number
  of t-shirts still available in that size.

*Important Note: the first version of this plugin will not have implemented 
the concept of a shopping cart, or the ability to queue up multiple items to be
purchased all at once. That is a feature planned for a future version.*

## Maintaining a Premium Service Level Subscription

Another common use case is for web sites who produce two or more levels of
content: the first being content that is freely available to everyone, and the
other levels being for content that is only available to paying subscribers. 

The model for this web site will be based around a blog for which entries are
associated with the level of service required to view the content of the entry. 
Whenever a user views an entry, the system will evaluate whether or not that
user has an active subscription, and whether that subscription entitles them to
view the content or not.

This implementation strategy relies on entry content to be delivered dynamically
so that the server can determine whether or not to transmit the privileged
content to the reader. 

**A word about dynamic content**

One of Movable Type's greatest perceived values in its ability to publish
"statically," which is considered by many to be the exact opposite of being 
published dynamically. Let's explain:

* Dynamic content is served straight from a database for each and every 
  request made to a web site. The most notable advantage of dynamic publishing
  is the immediacy with which changes appear on the site. Make a change to a
  template and presto the change is live. The trade off site owners make is in
  server stability. Surges in traffic can result in content being served more 
  slowly, and in severe cases content being completely unavailable.

* Static content is served directly from the file system. In this mode the page
  a user might request is processed and cached to disk *prior* to a user 
  requesting it. Then when they request the page, the web server sends them the
  cached version of the page saved on the filesystem without ever having to load
  content from the database. 

The conclusion many people make when contrasting these two publishing methods is
that static content cannot be customized on a user-by-user basis. While this *can* be true, it is not universally true. We exploit this fact in our 
implementation strategy for making premium content available to readers.

So, to be more precise, in Movable Type the term "static publishing" refers to 
how data is stored on disk, and *not* to how it is actually rendered and 
delivered to the end user. With this in mind, we use Movable Type to publish 
static PHP pages to disk. The advantage PHP provides is that PHP, unlike HTML, 
is processed and interpreted for each and every page request and therefore 
uniquely for each user. We will therefore place within these PHP pages all the 
logic necessary to deliver content dynamically for each user. This blends the 
best of both worlds and produces a site whose content is cached to disk with any 
calls to the database being minimized and restricted exclusively to evaluating 
whether a user has the access required to view the content being requested.

Now, time to let the rubber meet the road...

### A Step-by-Step Guide

The following guide shows two methodologies for how your theme and templates
will effectively enforce the access control policy for premium content. Regardless of the templating and publishing strategy you employ, the first two steps are the same:

1. **Create your blog**

  Login to Movable Type and create a new blog if you do not have one already.
  This blog will hold all of your web site's content. You will determine which
  content is accessible and to whom on an entry-by-entry basis.

2. **Create your custom field(s)**

  Next, you will need to a create a custom field into which you will enter for
  each entry the service/subscription level necessary to view the full post.

**Enforcing Subscription Levels**

To enforce a privacy policy, it is important to understand the specifics if that  
policy and what the resulting user experience is like. So let's assume for the
purposes of this demonstration, we want to implement the following privacy
policy. Let's also assume that our system contains only two entries, entry P
(a protected entry) and entry U (an unprotected entry).

* An excerpt of all entries on the site is visible to everyone at the very 
  least. Meaning if an unauthenticated user conducts a search on the site for 
  which entry U and P both match, they will be able see an excerpt for both
  entries.
  
* When the same user clicks on entry U, they will see the entire contents of 
  entry U. 
  
* When the same user clicks on entry P, a protected entry, they will be prompted
  for login credentials.
  
* When the user logs in, the system will evaluate their account to see if they 
  have an active subscription, if they do, then the system will present the full
  contents of the entry. If not, they will be prompted to upgrade their account
  to the premium service level. 

*Note: what is important to highlight in this scenario is that the existence of
protected content is made apparent to every user, regardless of their 
authentication and/or subscription status. This may not be desirable in
scenarios in which the existence of a protected document should only be revealed
to those with the proper access to view it.*

#### Method 1: Dynamic Publishing

The first method we will demonstrate is the use of Movable Type's native dynamic
publishing feature to render entry content in real time, and to completely
bypasses Movable Type's static publishing feature.

**Pros**

* Simple and fast to implement.
* Template logic much simpler.

**Cons**

* Dynamic publishing may leave server vulnerable to spikes in traffic.
* If you rely on template tags provided by 3rd party developers, it is unlikely
  that the developer implemented those template tags to be compatible with
  Movable Type's dynamic publishing system.

Here is an example Entry template that would effectively enforce your site's
subscription and privacy policy:

    <html>
      <body>
        <$mt:include module="Header"$>
        <h2><$mt:EntryTitle$></h2>
        <mt:IfUserHasActiveSubscription name="Premium">
          <$mt:EntryBody$>
          <h3>Comments</h3>
          <$mt:include module="Comments"$>
        <mt:Else>
          <$mt:EntryExcerpt$>
          <h3>Upgrade to view the rest!</h3>
          <$mt:include module="Sign-up and Upgrade Form"$>
        </mt:IfUserHasActiveSubscription>
        <$mt:include module="Footer"$>
      </body>
    </html>

#### Method 2: Using PHP

The second method utilizes static publishing to publish PHP files to your web
server. 

**Pros**

* Minimizes database access and increases site stability.
* Greater compatibility with 3rd party plugins.

**Cons**

* This methodology will not work in Movable Type system templates, only in
  index and archive templates.
* Slightly more complex template logic needed.
* Requires PHP (if that is at all an issue, which it shouldn't be).

And here is a sample entry template that would result in the same output as 
Method 1 above:

    <?php
    include("<$CGIServerPath$>plugins/StoreFront/php/mt.user.php");
    include("<$CGIServerPath$>plugins/StoreFront/php/mt.subscription.php");
    $user = new MTUser();
    ?>
    <html>
      <body>
        <$mt:include module="Header"$>
        <h2><$mt:EntryTitle$></h2>
    <?php
    if ( UserHasActiveSubscription($user,"Premium") ) {
    ?>
          <$mt:EntryBody$>
          <h3>Comments</h3>
          <$mt:include module="Comments"$>
    <?php
    } else {
    ?>
          <$mt:EntryExcerpt$>
          <h3>Upgrade to view the rest!</h3>
          <$mt:include module="Sign-up and Upgrade Form"$>
    <?php
    }
    ?>
        <$mt:include module="Footer"$>
      </body>
    </html>

**JAY: The above offers you only item level protection on a page.  It doesn't stop requests for assets other than particular page elements.  The way to do this is to route ALL requests through a gatekeeper script which is responsible for authentication.  If the request is allowed, it is passed through to the static files on the filesystem.  If not, it's redirected.  If the request is for a PHP page, you can provide data about the user (or lack of one) in the PHP session and let the requested PHP page handle what they can and can't see on that page.**


# Developer Guide

## PHP Library

## Building Payment Drivers

# License

This plugin is licensed under the same terms as Perl itself.
