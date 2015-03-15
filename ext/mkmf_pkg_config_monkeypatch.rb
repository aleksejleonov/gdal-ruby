# This is monkeypatch for Ruby 2.2.0+
# Method pkg_config is broken on Ubuntu 12.04, so I replace it to method from Ruby 2.1.5

if RUBY_VERSION >= '2.2.0'

  module MakeMakefile
    def pkg_config(pkg, option=nil)
      if pkgconfig = with_config("#{pkg}-config") and find_executable0(pkgconfig)
        # iff package specific config command is given
        get = proc {|opt| %x`#{pkgconfig} --#{opt}`.strip}
      elsif ($PKGCONFIG ||=
             (pkgconfig = with_config("pkg-config", ("pkg-config" unless CROSS_COMPILING))) &&
             find_executable0(pkgconfig) && pkgconfig) and
          system("#{$PKGCONFIG} --exists #{pkg}")
        # default to pkg-config command
        get = proc {|opt| %x`#{$PKGCONFIG} --#{opt} #{pkg}`.strip}
      elsif find_executable0(pkgconfig = "#{pkg}-config")
        # default to package specific config command, as a last resort.
        get = proc {|opt| %x`#{pkgconfig} --#{opt}`.strip}
      end
      orig_ldflags = $LDFLAGS
      if get and option
        get[option]
      elsif get and try_ldflags(ldflags = get['libs'])
        cflags = get['cflags']
        libs = get['libs-only-l']
        ldflags = (Shellwords.shellwords(ldflags) - Shellwords.shellwords(libs)).quote.join(" ")
        $CFLAGS += " " << cflags
        $CXXFLAGS += " " << cflags
        $LDFLAGS = [orig_ldflags, ldflags].join(' ')
        $libs += " " << libs
        Logging::message "package configuration for %s\n", pkg
        Logging::message "cflags: %s\nldflags: %s\nlibs: %s\n\n",
                         cflags, ldflags, libs
        [cflags, ldflags, libs]
      else
        Logging::message "package configuration for %s is not found\n", pkg
        nil
      end
    end
  end

end