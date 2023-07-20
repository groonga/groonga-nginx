# ngx\_http\_groonga\_module

This is a nginx module to use Groonga via HTTP.

This was formerly distributed with Groonga and provided as `groonga-httpd` with bundled nginx.

## Install

TODO

Debian/Ubuntu:

```console
$ apt install -y libngx-mod-http-groonga
```

## Configure

You need to configure your `nginx.conf` to use this module.

Load this module:

```nginx
load_module modules/ngx_http_groonga_module.so;
```

Add `location /d/` to use like [the Groonga http server](https://groonga.org/docs/reference/executables/groonga-server-http.html):

```nginx
# ...
http {
  # ...
  server {
    listen 10041;
    # ...
    location /d/ {
      groonga on;
      groonga_database /var/lib/groonga/db/db;
      # ...
    }
    # ...
  }
}
```

## License

LGPLv2.1 only.

See [COPYING](COPYING) for details.
