# **********************************************************************
#
# Copyright (c) 2003-2017 ZeroC, Inc. All rights reserved.
#
# **********************************************************************

require "mkmf"


if RUBY_PLATFORM =~ /mswin|mingw/
    puts "MinGW is not supported with Ice for Ruby."
    exit 1
end

#
# On OSX & Linux bzlib.h is required.
#
if not have_header("bzlib.h") then
    exit 1
end

if RUBY_PLATFORM =~ /linux/
    #
    # On Linux openssl is required for IceSSL.
    #
    if not have_header("openssl/ssl.h") then
        exit 1
    end
end

#
# Ice on OSX is built only with 64 bit support.
#
if RUBY_PLATFORM =~ /darwin/
    $ARCH_FLAG = "-arch x86_64"
end

$INCFLAGS << ' -Iice/cpp/include'
$INCFLAGS << ' -Iice/cpp/include/generated'
$INCFLAGS << ' -Iice/cpp/src'

$CPPFLAGS << ' -DICE_STATIC_LIBS'

if RUBY_PLATFORM =~ /darwin/
    $LOCAL_LIBS << ' -framework Security -framework CoreFoundation'
elsif RUBY_PLATFORM =~ /linux/
    $LOCAL_LIBS << ' -lssl -lcrypto -lbz2 -lrt'
        if RUBY_VERSION =~ /1.8/
            # With 1.8 we need to link with C++ runtime, as gcc is used to link the extension
            $LOCAL_LIBS << ' -lstdc++'
            # With 1.8 we need to fix the objects output directory
            $CPPFLAGS << ' -o$@'
            # With 1.8 /usr/lib/ruby/1.8/regex.h conflicts with /usr/include/regex.h
            # we add a symbolic link to workaround the problem
            if File.exist?('/usr/include/regex.h') && !File.exist?('regex.h')
                FileUtils.ln_s '/usr/include/regex.h', 'regex.h'
            end
        end
end
$CPPFLAGS << ' -w'

# Setup the object and source files.
$objs = []
$srcs = []

# Add the plugin source.
Dir["*.cpp"].each do |f|
    $objs << File.basename(f, ".*") + ".o"
    $srcs << f
end

# The Ice source.
skip = []

Dir["ice/**/*.cpp"].each do |f|
    if ! skip.include? File.basename(f)
        $objs << File.dirname(f) + "/" + File.basename(f, ".*") + ".o"
        $srcs << f
    end
end

# The mcpp source.
Dir["ice/mcpp/*.c"].each do |f|
    dir = "ice/mcpp"
    $objs << File.join(dir, File.basename(f, ".*") + ".o")
    $srcs << File.join(dir, f)
end

create_makefile "IceRuby"
