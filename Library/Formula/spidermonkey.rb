require 'formula'

# Private older version of autoconf required to compile Spidermonkey
class Autoconf213 < Formula
  homepage 'http://www.gnu.org/software/autoconf/'
  url 'http://ftpmirror.gnu.org/autoconf/autoconf-2.13.tar.gz'
  mirror 'http://ftp.gnu.org/gnu/autoconf/autoconf-2.13.tar.gz'
  sha1 'e4826c8bd85325067818f19b2b2ad2b625da66fc'
end

class Spidermonkey < Formula
  homepage 'https://developer.mozilla.org/en/SpiderMonkey'
  url 'http://ftp.mozilla.org/pub/mozilla.org/js/js185-1.0.0.tar.gz'
  version '1.8.5'
  sha1 '52a01449c48d7a117b35f213d3e4263578d846d6'

  head 'https://hg.mozilla.org/tracemonkey/archive/tip.tar.gz'

  depends_on 'readline'
  depends_on 'nspr'

  def install
    # aparently this flag causes the build to fail for ivanvc on 10.5 with a
    # penryn (core 2 duo) CPU. So lets be cautious here and remove it.
    ENV['CFLAGS'] = ENV['CFLAGS'].gsub(/-msse[^\s]+/, '') if MacOS.version == :leopard

    # For some reason SpiderMonkey requires Autoconf-2.13
    ac213_prefix = buildpath/'ac213'
    Autoconf213.new.brew do |f|
      # Force use of plain "awk"
      inreplace 'configure', 'for ac_prog in mawk gawk nawk awk', 'for ac_prog in awk'

      system "./configure", "--disable-debug",
                            "--program-suffix=213",
                            "--prefix=#{ac213_prefix}"
      system "make install"
    end

    cd "js/src" do
      system "#{ac213_prefix}/bin/autoconf213"

      # Remove the broken *(for anyone but FF) install_name
      inreplace "config/rules.mk",
        "-install_name @executable_path/$(SHARED_LIBRARY) ",
        "-install_name #{lib}/$(SHARED_LIBRARY) "
    end

    mkdir "brew-build" do
      system "../js/src/configure", "--prefix=#{prefix}",
                                    "--enable-readline",
                                    "--enable-threadsafe",
                                    "--with-system-nspr"

      inreplace "js-config", /JS_CONFIG_LIBS=.*?$/, "JS_CONFIG_LIBS=''"
      # These need to be in separate steps.
      system "make"
      system "make install"

      # Also install js REPL.
      bin.install "shell/js"
    end
  end
end
