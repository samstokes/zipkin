include_recipe 'apt'

package 'build-essential'
package 'automake'
package 'autoconf'
package 'libevent-dev'
package 'libboost-dev'
package 'libboost-filesystem-dev'
package 'libboost-system-dev'
package 'git'


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

bash "compile and install fb303" do
  cwd "/tmp/thrift-#{THRIFT_VERSION}/contrib/fb303"

  code <<-BASH
    set -e
    find . -type f | xargs perl -p -i -e 's/facebook/apache/g'
    ./bootstrap.sh
    make
    sudo make install
  BASH

  creates "#{PREFIX}/lib/libfb303.a"
end


bash "clone and patch scribe" do
  cwd '/tmp'

  code <<-BASH
    set -e
    git clone https://github.com/facebook/scribe.git

    cd scribe

    # https://github.com/facebook/scribe/pull/55
    # https://github.com/powermedia/scribe/commit/6a3201f5c9b21e324e9530ff12def27cabf501d4
    patch -p1 <<'PATCH'
diff --git a/src/Makefile.am b/src/Makefile.am
index 969775a..5f2e5d9 100644
--- a/src/Makefile.am
+++ b/src/Makefile.am
@@ -72,7 +72,7 @@ AM_CPPFLAGS += -I$(hadoop_home)/include
 AM_CPPFLAGS += $(BOOST_CPPFLAGS)
 AM_CPPFLAGS += $(FB_CPPFLAGS) $(DEBUG_CPPFLAGS)
 
-AM_LDFLAGS = $(BOOST_LDFLAGS) $(BOOST_SYSTEM_LIB) $(BOOST_FILESYSTEM_LIB)
+AM_LDFLAGS = -Wl,--no-as-needed $(BOOST_LDFLAGS) $(BOOST_SYSTEM_LIB) $(BOOST_FILESYSTEM_LIB)
 
 # Section 3 #############################################################################
 # GENERATE BUILD RULES
PATCH

    # https://github.com/facebook/scribe/issues/36
    patch -p1 <<'PATCH'
diff --git a/src/file.cpp b/src/file.cpp
index d629c2f..f6591ff 100644
--- a/src/file.cpp
+++ b/src/file.cpp
@@ -245,7 +245,7 @@ void StdFile::listImpl(const std::string& path, std::vector<std::string>& _retur
       boost::filesystem::directory_iterator dir_iter(path), end_iter;
 
       for ( ; dir_iter != end_iter; ++dir_iter) {
-        _return.push_back(dir_iter->filename());
+        _return.push_back(dir_iter->path().filename().string());
       }
     }
   } catch (const std::exception& e) {
PATCH

    find . -type f | xargs perl -p -i -e 's/facebook/apache/g'
  BASH

  creates '/tmp/scribe/bootstrap.sh'
end

bash "compile and install scribe" do
  cwd '/tmp/scribe'

  code <<-BASH
    set -e
    ./bootstrap.sh
    make
    sudo make install
  BASH

  not_if 'which scribed'
end


directory '/usr/local/scribe' do
  owner 'root'
end

template '/usr/local/scribe/scribe.conf' do
  source 'scribe.conf.erb'
  owner 'root'
  mode  0755
end
