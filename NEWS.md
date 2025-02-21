# NEWS

## 1.0.1 - 2025-02-21

### Package distribution update

In previous releases, Ubuntu packages were available only through the Groonga
APT repository. Starting with this release, packages are also distributed via
packages.groonga.org.

### Migration Notice for groonga-nginx

If you’re currently using groonga-nginx, we recommend migrating to the packages
provided by groonga.packages.org. Although the Groonga APT repository will still
be available, it will no longer receive new updates in near future.

For migration, please follow these steps:

```console
$ sudo add-apt-repository --remove ppa:groonga/ppa
$ sudo apt install -y -V ca-certificates lsb-release wget
$ wget https://apache.jfrog.io/artifactory/arrow/$(lsb_release --id --short | tr 'A-Z' 'a-z')/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
$ sudo apt install -y -V ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
$ rm -f apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb
$ wget https://packages.groonga.org/debian/groonga-apt-source-latest-$(lsb_release --codename --short).deb
$ sudo apt install -y -V ./groonga-apt-source-latest-$(lsb_release --codename --short).deb
$ rm -f groonga-apt-source-latest-$(lsb_release --codename --short).deb
$ sudo apt update
$ sudo apt update -y -V libnginx-mod-http-groonga
```

## 1.0.0 - 2023-07-21

Initial release!
