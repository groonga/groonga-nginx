# groonga-nginx

This is a nginx module to use Groonga via HTTP.

This was formerly distributed with Groonga and provided as `groonga-httpd` with bundled nginx.

## Install

Debian:

```console
$ sudo apt install -y -V ca-certificates lsb-release wget
$ wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
$ sudo apt install -y -V ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
$ rm -f apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
$ wget https://packages.groonga.org/debian/groonga-apt-source-latest-$(lsb_release --codename --short).deb
$ sudo apt install -y -V ./groonga-apt-source-latest-$(lsb_release --codename --short).deb
$ rm -f groonga-apt-source-latest-$(lsb_release --codename --short).deb
$ sudo apt update
$ sudo apt install -y -V libnginx-mod-http-groonga
$ sudo cp /etc/nginx/groonga.conf /etc/nginx/conf.d/
$ sudo editor /etc/nginx/conf.d/groonga.conf
$ sudo systemctl restart nginx
```

Ubuntu:

```console
$ sudo apt -y -V install software-properties-common
$ sudo add-apt-repository -y universe
$ sudo add-apt-repository -y ppa:groonga/ppa
$ sudo apt install -y -V libnginx-mod-http-groonga
$ sudo cp /etc/nginx/groonga.conf /etc/nginx/conf.d/
$ sudo editor /etc/nginx/conf.d/groonga.conf
$ sudo systemctl restart nginx
```

## Configure

You need to configure your `/etc/nginx/conf.d/groonga.conf` to use this module.

### Basic directives

#### `groonga`

Syntax: `groonga on | off`;

Default: `groonga off`

Context: `location`

Specifies whether Groonga is enabled in the ``location`` block. The
default is ``off``. You need to specify ``on`` to enable groonga.

Examples:

```nginx
location /d/ {
  groonga on;  # Enables groonga under /d/... path
}

location /d/ {
  groonga off; # Disables groonga under /d/... path
}
```

#### `groonga_database`

Syntax: `groonga_database /path/to/groonga/database;`

Default: None

Context: `main`, `http`, `server`, `location`

Specifies the path to a Groonga database. This is the required
directive.

#### `groonga_database_auto_create`

Syntax: `groonga_database_auto_create on | off;`

Default: `groonga_database_auto_create on;`

Context: `main`, `http`, `server`, `location`

Specifies whether Groonga database is created automatically or not. If
the value is `on` and the Groonga database specified by
`groonga-httpd-groonga-database` doesn't exist, the Groonga database
is created automatically. If the Groonga database exists, this module
does nothing.

If parent directory doesn't exist, parent directory is also created
recursively.

The default value is `on`. Normally, the value doesn't need to be
changed.

#### `groonga_base_path`

Syntax: `groonga_base_path /d/;`

Default: The same value as `location` name.

Context: `location`

Specifies the base path in URI. Groonga uses
`/d/command?parameter1=value1&...` path to run `command`. The form of
path in used in groonga-nginx but groonga-nginx also supports
`/other-prefix/command?parameter1=value1&...` form. To support the
form, groonga-nginx removes the base path from the head of request URI
and prepend `/d/` to the processed request URI. By the path
conversion, users can use custom path prefix and Groonga can always
uses `/d/command?parameter1=value1&...` form.

Nomally, this directive isn't needed. It is needed for per command
configuration.

Here is an example configuration to add authorization to
`shutdown` command:

```nginx
groonga_database /var/lib/groonga/db/db;

location /d/shutdown {
  groonga on;
  # groonga_base_path is needed.
  # Because /d/shutdown is handled as the base path.
  # Without this configuration, /d/shutdown/shutdown path is required
  # to run shutdown command.
  groonga_base_path /d/;
  auth_basic           "manager is required!";
  auth_basic_user_file "/etc/managers.htpasswd";
}

location /d/ {
  groonga on;
  # groonga_base_path doesn't needed.
  # Because location name is the base path.
}
```

#### `groonga_log_path`

Syntax: `groonga_log_path path | off;`

Default:
  * `groonga_log_path /var/log/nginx/groonga.log;` for deb packages.
  * `groonga_log_path logs/groonga.log;` for source build.

Context: `main`, `http`, `server`, `location`

Specifies Groonga log path in the `main`, `http`, `server` or
`location` block. The default is `/var/log/nginx/groonga.log` for deb
packages.  You can disable logging by specifing `off`.

Examples:

```nginx
location /d/ {
  groonga on;
  # You can disable log for groonga.
  groonga_log_path off;
}
```

#### `groonga_log_level`

Syntax: `groonga_log_level none | emergency | alert | ciritical | error | warning | notice | info | debug | dump;`

Default: `notice`

Context: `main`, `http`, `server`, ``location`

Specifies Groonga log level in the `main`, `http`, `server` or
`location` block. The default is `notice`. You can disable logging
by specifying `none` as log level.

Examples:

```nginx
location /d/ {
  groonga on;
  # You can customize log level for groonga.
  groonga_log_level notice;
}
```

#### `groonga_query_log_path`

Syntax: `groonga_query_log_path path | off;`

Default:
* `groonga_query_log_path  /var/log/nginx/groonga-query.log;` for deb packages.
* `groonga_query_log_path logs/groonga-query.log;` for source build.

Context: `main`, `http`, `server`, `location`

Specifies Groonga's query log path in the `main`, `http`, `server` or
`location` block. The default is `/var/log/nginx/groonga-query.log`
for deb packages and `logs/groonga-query.log` for source build. You
can disable logging to specify ``off``.

Examples:

```nginx
location /d/ {
  groonga on;
  # You can disable query log for groonga.
  groonga_query_log_path off;
}
```

Query log is useful for the following cases:

  * Detecting slow query.
  * Debugging.

You can analyze your query log by [groonga-query-log
package](https://github.com/groonga/groonga-query-log). The package
provides useful tools.

For example, there is a tool that analyzing your query log. It can
detect slow queries from your query log. There is a tool that
replaying same queries in your query log. It can test the new Groonga
before updating production environment.

### Performance related directives

The following directives are related to the performance of groonga-nginx.

#### `worker_processes`

For optimum performance, set this to be equal to the number of CPUs or
cores. In many cases, Groonga queries may be CPU-intensive work, so to
fully utilize multi-CPU/core systems, it's essential to set this
accordingly.

This isn't a groonga-nginx specific directive, but an nginx's one. For
details, see https://nginx.org/en/docs/ngx_core_module.html#worker_processes .

By default, this is set to 1. It is nginx's default.

#### `groonga_cache_limit`

Syntax: `groonga_cache_limit limit;`

Default: `groonga_cache_limit 100;`

Context: `main`, `http`, `server`, `location`

Specifies Groonga's limit of query cache in the `main`, `http`,
`server` or `location` block. The default value is `100`.  You can
disable query cache to specify `0` to ``groonga_cache_limit``
explicitly.

Examples:

```nginx
location /d/ {
  groonga on;
  # You can customize query cache limit for groonga.
  groonga_cache_limit 100;
}
```

#### `groonga_cache_base_path`

Syntax: `groonga_cache_base_path path | off;`

Default: `groonga_cache_base_path off;`

Context: `main`, `http`, `server`, `location`

Specifies the base path of query cache in the `main`, `http`, `server`
or `location` block.

It's recommended that you specify this configuration when you use
multi-workers configuration.

If the base path is specified, you can use persistent cache instead of
on memory cache. If you use persistent cache, workers share query
cache. It's efficient for multi-workers configuration because the same
response is cached only once in multiple workers.

There is one more merit for persistent cache. You don't need to warm
up cache after groonga-httpd is restarted. Persistent cache isn't
cleared when groonga-httpd is down. groonga-httpd can use existing
persistent cache again.

The default value is `off`. It means that persistent cache is
disabled. On memory cache is used. On memory cache is independent in
each worker. It's not efficient for multi-workers configuration
because two or more workers may keeps the same response separately.

Persistent cache is a bit slower than on memory cache. Normally, the
difference has little influence on performance.

You must specify the base path on memory file system. If you specify
the base path on disk, your cache will be slow. It's not make sense.

Examples:

```nginx
location /d/ {
  groonga on;
  # You can customize query cache limit for groonga.
  groonga_cache_base_path /dev/shm/groonga-httpd-cache;
}
```

## License

LGPLv2.1 only.

See [COPYING](COPYING) for details.
