require 'simplecov'
SimpleCov.start

require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'xbuilder'

class Test::Unit::TestCase
  def without_instruct(xml)
    xml.gsub(/^\s*<\?xml[^>]*>\n/, "").rstrip
  end
end
