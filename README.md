# PrimeGap Monitor Dashboard

## Getting started

- Use the Gemfile to install all (missing) libraries

```
$ bundle install
```

- Run (rackup) your web app (will use the settings in `config.ru`)

```
$ rackup
```

Resulting in:

```
Thin Web server (v1.7.2 codename Protein Powder)
Listening on localhost:9292, CTRL+C to stop
```

- Open up the web page (e.g. `http://localhost:9292`) in your browser

That's it.

## ENV Variables

- `AUTH_USER`: username for http basic authentication
- `AUTH_PSWD`: password for http basic authentication
- `PORT`: port to run the webserver on
- `HEROKU_API_TOKEN`: heroku api token to access the apps ([official documentation](https://devcenter.heroku.com/articles/platform-api-quickstart#authentication))
