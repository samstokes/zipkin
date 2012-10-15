include_recipe 'apt'

package 'build-essential'
package 'libevent-dev'
package 'libboost-dev'


PREFIX = '/usr/local'
THRIFT_VERSION = '0.5.0'


tempdir = Dir.tmpdir
thrift_tgz = File.join(tempdir, "thrift-#{THRIFT_VERSION}.tar.gz")

remote_file(thrift_tgz) do
  source "https://archive.apache.org/dist/incubator/thrift/#{THRIFT_VERSION}-incubating/thrift-#{THRIFT_VERSION}.tar.gz"
  action :create_if_missing
  mode '755'
end

bash "extract thrift tarball" do
  cwd '/tmp'

  code "tar zxf #{thrift_tgz}"

  creates "/tmp/thrift-#{THRIFT_VERSION}/configure"
end

bash "compile and install thrift" do
  cwd "/tmp/thrift-#{THRIFT_VERSION}"

  code <<-BASH
    set -e
    ./configure --with-php=no --with-php_extension=no --with-ruby=no --with-python=no
    make
    sudo make install
  BASH

  creates "#{PREFIX}/lib/pkgconfig/thrift.pc"
end
