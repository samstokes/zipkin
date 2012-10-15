include_recipe 'apt'

package 'build-essential'
package 'libevent-dev'
package 'libboost-dev'


PREFIX = '/usr/local'
THRIFT_VERSION = '0.8.0'


tempdir = Dir.tmpdir
thrift_tgz = File.join(tempdir, "thrift-#{THRIFT_VERSION}.tar.gz")

remote_file(thrift_tgz) do
  source "https://dist.apache.org/repos/dist/release/thrift/#{THRIFT_VERSION}/thrift-#{THRIFT_VERSION}.tar.gz"
  action :create_if_missing
  mode '755'
end

bash "extract thrift tarball" do
  cwd '/tmp'

  code "gunzip <#{thrift_tgz} | tar zxf -" # WTF - somehow we get a tar.gz.gz

  creates "/tmp/thrift-#{THRIFT_VERSION}/configure"
end

bash "compile and install thrift" do
  cwd "/tmp/thrift-#{THRIFT_VERSION}"

  code <<-BASH
    set -e
    ./configure
    make
    sudo make install
  BASH

  creates "#{PREFIX}/lib/pkgconfig/thrift.pc"
end
