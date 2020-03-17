# Newsletter

Build and send HTML and Plaintext Newsletters

## Usage

Create a `source.json` file in `newsletters/YYYY-MM-DD/` directory. See examples directory.

Then build the email with `build`:

```ruby
build newsletters/YYYY-MM-DD/source.json
```

There should be a new file at `newsletters/YYYY-MM-DD/mail.eml`

To send the newsletter run:

```ruby
send newsletters/YYYY-MM-DD/mail.eml
```

### UI

Run the server using `rackup` in the `app` directory. Then go to `localhost:9292` in the browser.

## GMail API

If you have not already done it (missing credentials.json file in this directory), you need to [enable the GMail API](https://developers.google.com/gmail/api/quickstart/ruby).

## Authorization

The first time you run the `send` script, there will be a URL printed to stdout. Go to that URL in the browser and authorize that application. Your token will be saved in `token.yaml`, so you only have to do it once.

## Styles

Style files are found in the `styles/` directory.

HINT: HTML gradents can be made here: https://cssgradient.io/
