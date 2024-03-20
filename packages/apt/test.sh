#!/bin/bash
#
# Copyright(C) 2023  Sutou Kouhei <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

set -eux

echo "::group::Prepare external repositories"

echo "debconf debconf/frontend select Noninteractive" | \
  sudo debconf-set-selections

sudo apt update
sudo apt install -V -y lsb-release wget

distribution=$(lsb_release --id --short | tr 'A-Z' 'a-z')
case ${distribution} in
  debian)
    repository=main
    ;;
  ubuntu)
    repository=universe
    sudo apt -y install software-properties-common
    sudo add-apt-repository -y universe
    sudo add-apt-repository -y ppa:groonga/ppa
    ;;
esac
code_name=$(lsb_release --codename --short)
architecture=$(dpkg --print-architecture)

wget \
   https://apache.jfrog.io/artifactory/arrow/${distribution}/apache-arrow-apt-source-latest-${code_name}.deb
sudo apt install -V -y ./apache-arrow-apt-source-latest-${code_name}.deb
wget \
  https://packages.groonga.org/${distribution}/groonga-apt-source-latest-${code_name}.deb
sudo apt install -V -y ./groonga-apt-source-latest-${code_name}.deb
sudo apt update

echo "::endgroup::"


echo "::group::Prepare local repository"

(echo "Key-Type: RSA"; \
 echo "Key-Length: 4096"; \
 echo "Name-Real: Test"; \
 echo "Name-Email: test@example.com"; \
 echo "%no-protection") | \
  gpg --full-generate-key --batch
GPG_KEY_ID=$(gpg --list-keys --with-colon test@example.com | grep fpr | cut -d: -f10)
gpg --export --armor test@example.com > keys
sudo gpg \
  --no-default-keyring \
  --keyring /usr/share/keyrings/groonga-nginx.gpg \
  --import keys

sudo apt install -V -y reprepro
repositories_dir=/host/packages/apt/repositories
pushd /tmp/
mkdir -p conf/
cat <<DISTRIBUTIONS > conf/distributions
Codename: ${code_name}
Components: main
Architectures: ${architecture} source
SignWith: ${GPG_KEY_ID}
DISTRIBUTIONS
reprepro includedeb ${code_name} \
  ${repositories_dir}/${distribution}/pool/${code_name}/${repository}/*/*/*_${architecture}.deb
cat <<APT_SOURCES | sudo tee /etc/apt/sources.list.d/groonga-nginx.list
deb [signed-by=/usr/share/keyrings/groonga-nginx.gpg] file://${PWD} ${code_name} main
APT_SOURCES
popd

echo "::endgroup::"


echo "::group::Install"
sudo apt update
sudo apt install -V -y libnginx-mod-http-groonga
echo "::endgroup::"


echo "::group::Enable"
sudo ln -s ../groonga.conf /etc/nginx/conf.d/
sudo systemctl restart nginx
echo "::endgroup::"


echo "::group::Connection test"
sudo apt install -V -y jq curl
curl http://localhost:10041/d/status | tee status.json
groonga_version=$(jq -r '.[1].version' status.json)
echo "::endgroup::"


echo "::group::Prepare test"
sudo apt install -V -y \
  gcc \
  git \
  groonga-bin \
  groonga-tokenizer-mecab \
  libarrow-glib-dev \
  make \
  ruby-dev
sudo env MAKEFLAGS=-j$(nproc) gem install \
  grntest \
  pkg-config \
  red-arrow
export TZ=Asia/Tokyo
PATH=/usr/sbin:$PATH
git clone \
  --branch v${groonga_version} \
  https://github.com/groonga/groonga.git
echo "::endgroup::"


echo "::group::Test"
cd groonga
grntest \
  --base-dir=test/command \
  --n-retries=2 \
  --ngx-http-groonga-module-so=/usr/lib/nginx/modules/ngx_http_groonga_module.so \
  --read-timeout=30 \
  --reporter=mark \
  --testee=groonga-nginx \
  test/command/suite
echo "::endgroup::"


