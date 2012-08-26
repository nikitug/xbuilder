$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'xbuilder'
require 'builder'
require 'nokogiri'
require 'benchmark'

xml_block = proc do |xml|
  xml.root do |xml|
    10.times do
      xml.node "text"
      xml.node2 do |xml|
        xml.test args: 1, args2: 4 do |xml|
          xml.child arg: "text" do |xml|
            xml.one_more arg: 1, arg: "2123"
          end
        end
      end
    end
  end
end

repeat = 200
xmls = []
Benchmark.bm do |x|
  x.report "builder" do
    repeat.times do
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml_block.call(xml)
      xmls << xml.target!
    end
  end
  x.report "nokogiri" do
    repeat.times do
      builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
        xml_block.call(xml)
      end
      xmls << builder.to_xml(indent: 0)
    end
  end
  x.report "xbuilder" do
    repeat.times do
      xml = Xbuilder.new
      xml_block.call(xml)
      xmls << xml.target!
    end
  end
end

# Enshure all xmls are the same.
xml = xmls.first.split.join
xmls.each do |xml2|
  if xml != xml2.split.join
    puts xml
    puts xml2
    exit
  end
end

require 'ruby-prof'

RubyProf.start
repeat.times do
  xml = Xbuilder.new
  xml_block.call(xml)
  xmls << xml.target!
end
result = RubyProf.stop

printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
