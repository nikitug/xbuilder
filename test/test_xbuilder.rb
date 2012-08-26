require 'helper'

#--
# To enshure compatibility, a significant part of this test was taken from Builder gem.
#
# Portions copyright 2004 by Jim Weirich (jim@weirichhouse.org).
# Portions copyright 2005 by Sam Ruby (rubys@intertwingly.net).
# Portions copyright 2012 by Nikita Afanasenko (nikita@afanasenko.name).
# All rights reserved.

# Permission is granted for use, copying, modification, distribution,
# and distribution of modified versions of this work as long as the
# above copyright notice is included.
#++

class TestXbuilder < Test::Unit::TestCase
  def setup
    @xml = Xbuilder.new
  end

  def test_simple
    @xml.simple
    assert_equal "<simple/>", without_instruct(@xml.target!)
  end

  def test_value
    @xml.value("hi")
    assert_equal "<value>hi</value>", without_instruct(@xml.target!)
  end

  def test_nested
    @xml.outer { |x| x.inner("x") }
    assert_equal "<outer><inner>x</inner></outer>", without_instruct(@xml.target!)
  end

  def test_attributes
    @xml.ref(:id => 12)
    assert_equal %{<ref id="12"/>}, without_instruct(@xml.target!)
  end

  def test_string_attributes_are_quoted_by_default
    @xml.ref(:id => "H&R")
  end

  def test_symbol_attributes_are_unquoted_by_default
    skip "Unquoted symbol attributes are not supported."
    @xml.ref(:id => :"H&amp;R")
    assert_equal %{<ref id="H&amp;R"/>}, without_instruct(@xml.target!)
  end

  def test_attributes_quoted_can_be_turned_on
    @xml.ref(:id => "<H&R \"block\">")
    assert_equal %{<ref id="&lt;H&amp;R &quot;block&quot;&gt;"/>}, without_instruct(@xml.target!)
  end

  def test_multiple_attributes
    @xml.ref(:id => 12, :name => "bill")
    assert_match %r{^<ref( id="12"| name="bill"){2}/>$}, without_instruct(@xml.target!)
  end

  def test_attributes_with_text
    @xml.a("link", :href=>"http://onestepback.org")
    assert_equal %{<a href="http://onestepback.org">link</a>}, without_instruct(@xml.target!)
  end

  def test_complex
    @xml.body(:bg=>"#ffffff") { |x|
      x.title("T", :style=>"red")
    }
    assert_equal %{<body bg="#ffffff"><title style="red">T</title></body>}, without_instruct(@xml.target!)
  end

  def test_funky_symbol
    @xml.tag!("non-ruby-token", :id=>1) { |x| x.ok }
    assert_equal %{<non-ruby-token id="1"><ok/></non-ruby-token>}, without_instruct(@xml.target!)
  end

  def test_tag_can_handle_private_method
    @xml.tag!("loop", :id=>1) { |x| x.ok }
    assert_equal %{<loop id="1"><ok/></loop>}, without_instruct(@xml.target!)
  end

  def test_no_explicit_marker
    @xml.p { |x| x.b("HI") }
    assert_equal "<p><b>HI</b></p>", without_instruct(@xml.target!)
  end

  def test_reference_local_vars
    n = 3
    @xml.ol { |x| n.times { x.li(n) } }
    assert_equal "<ol><li>3</li><li>3</li><li>3</li></ol>", without_instruct(@xml.target!)
  end

  def test_reference_methods
    @xml.title { |x| x.a { |x| x.b(name) } }
    assert_equal "<title><a><b>bob</b></a></title>", without_instruct(@xml.target!)
  end

  def test_append_text
    @xml.p { |x| x.br; x.text! "HI" }
    assert_equal "<p><br/>HI</p>", without_instruct(@xml.target!)
  end

  def test_ambiguous_markup
    ex = assert_raise(ArgumentError) {
      @xml.h1("data1") { b }
    }
    assert_match /\btext\b/, ex.message
    assert_match /\bblock\b/, ex.message
  end

  def test_capitalized_method
    @xml.P { |x| x.B("hi"); x.BR(); x.EM { |x| x.text! "world" } }
    assert_equal "<P><B>hi</B><BR/><EM>world</EM></P>", without_instruct(@xml.target!)
  end

  def test_escaping
    @xml.div { |x| x.text! "<hi>"; x.em("H&R Block") }
    assert_equal %{<div>&lt;hi&gt;<em>H&amp;R Block</em></div>}, without_instruct(@xml.target!)
  end

  def test_non_escaping
    @xml.div("ns:xml"=>"xml") { |x| x << "<h&i>"; x.em("H&R Block") }
    assert_equal %{<div ns:xml="xml"><h&i><em>H&amp;R Block</em></div>}, without_instruct(@xml.target!)
  end

  def test_content_non_escaping
    @xml.div { |x| x << "<h&i>" }
    assert_equal %{<div><h&i></div>}, without_instruct(@xml.target!)
  end

  def test_content_escaping
    @xml.div { |x| x.text!("<hi>") }
    assert_equal %{<div>&lt;hi&gt;</div>}, without_instruct(@xml.target!)
  end

  def test_return_value
    str = @xml.x("men").to_s
    assert_equal without_instruct(@xml.target!), str
  end

  def test_stacked_builders
    ex = assert_raise(ArgumentError) { Xbuilder.new( :target => @xml ) }
    assert_match /target/, ex.message
  end

  def name
    "bob"
  end
end

class TestAttributeEscaping < Test::Unit::TestCase
  def setup
    @xml = Xbuilder.new
  end

  def test_element_gt
    @xml.title('1<2')
    assert_equal '<title>1&lt;2</title>', without_instruct(@xml.target!)
  end

  def test_element_amp
    @xml.title('AT&T')
    assert_equal '<title>AT&amp;T</title>', without_instruct(@xml.target!)
  end

  def test_element_amp2
    @xml.title('&amp;')
    assert_equal '<title>&amp;</title>', without_instruct(@xml.target!)
  end

  def test_attr_less
    @xml.a(:title => '2>1')
    assert_equal '<a title="2&gt;1"/>', without_instruct(@xml.target!)
  end

  def test_attr_amp
    @xml.a(:title => 'AT&T')
    assert_equal '<a title="AT&amp;T"/>', without_instruct(@xml.target!)
  end

  def test_attr_quot
    @xml.a(:title => '"x"')
    assert_equal '<a title="&quot;x&quot;"/>', without_instruct(@xml.target!)
  end

end

class TestNameSpaces < Test::Unit::TestCase
  def setup
    @xml = Xbuilder.new(:indent=>2)
  end

  def test_simple_name_spaces
    @xml.rdf :RDF
    assert_equal "<rdf:RDF/>", without_instruct(@xml.target!)
  end
end

class TestSpecialMarkup < Test::Unit::TestCase
  def setup
    @xml = Xbuilder.new(:indent=>2)
  end

  def test_comment
    @xml.comment!("COMMENT")
    assert_equal "<!--COMMENT-->", without_instruct(@xml.target!)
  end

  def test_indented_comment
    @xml.p { |x| x.comment! "OK" }
    assert_equal "<p>\n  <!--OK-->\n</p>", without_instruct(@xml.target!)
  end

  def test_instruct
    skip "Custom instructs are not supported yet."
    @xml.instruct! :abc, :version=>"0.9"
    assert_equal "<?abc version=\"0.9\"?>\n", without_instruct(@xml.target!)
  end

  def test_indented_instruct
    skip "Custom instructs are not supported yet."
    @xml.p { @xml.instruct! :xml }
    assert_match %r{<p>\n  <\?xml version="1.0" encoding="UTF-8"\?>\n</p>\n},
      without_instruct(@xml.target!)
  end

  def test_instruct_without_attributes
    skip "Custom instructs are not supported yet."
    @xml.instruct! :zz
    assert_equal "<?zz?>\n", without_instruct(@xml.target!)
  end

  def test_xml_instruct
    #@xml.instruct!
    assert_match /^<\?xml version="1.0" encoding="UTF-8"\?>$/, @xml.target!
  end

  def test_xml_instruct_with_overrides
    skip "Custom instructs are not supported yet."
    # FIXME shoud deal with encodings
    @xml.instruct! :xml, :encoding=>"UCS-2"
    assert_match /^<\?xml version="1.0" encoding="UCS-2"\?>$/, without_instruct(@xml.target!)
  end

  def test_xml_instruct_with_standalong
    skip "Custom instructs are not supported yet."
    @xml.instruct! :xml, :encoding=>"UCS-2", :standalone=>"yes"
    assert_match /^<\?xml version="1.0" encoding="UCS-2" standalone="yes"\?>$/, without_instruct(@xml.target!)
  end

  def test_no_blocks
    assert_raise(ArgumentError) do
      @xml.cdata!("test") { |x| x.hi }
    end
    assert_raise(ArgumentError) do
      @xml.comment!(:element) { |x| x.hi }
    end
  end

  def test_block_arity_check
    assert_raise(ArgumentError) do
      @xml.node { x.hi }
    end
  end

  def test_cdata
    @xml.cdata!("TEST")
    assert_equal "<![CDATA[TEST]]>", without_instruct(@xml.target!)
  end

  def test_cdata_with_ampersand
    @xml.cdata!("TEST&CHECK")
    assert_equal "<![CDATA[TEST&CHECK]]>", without_instruct(@xml.target!)
  end
end

class TestIndentedXmlMarkup < Test::Unit::TestCase
  def setup
    @xml = Xbuilder.new(:indent=>2)
  end

  def test_one_level
    @xml.ol { |x| x.li "text" }
    assert_equal "<ol>\n  <li>text</li>\n</ol>", without_instruct(@xml.target!)
  end

  def test_two_levels
    @xml.p { |x|
      x.ol { |x| x.li "text" }
      x.br
    }
    assert_equal "<p>\n  <ol>\n    <li>text</li>\n  </ol>\n  <br/>\n</p>", without_instruct(@xml.target!)
  end

  def test_initial_level
    @xml = Xbuilder.new(:indent=>2, :margin=>4)
    @xml.name { |x| x.first("Jim") }
    assert_equal "        <name>\n          <first>Jim</first>\n        </name>", without_instruct(@xml.target!)
  end
end

# FIXME should it be supported?
#
#class TestUtfMarkup < Test::Unit::TestCase
  #if ! String.method_defined?(:encode)
    #def setup
      #@old_kcode = $KCODE
    #end

    #def teardown
      #$KCODE = @old_kcode
    #end

    #def test_use_entities_if_no_encoding_is_given_and_kcode_is_none
      #$KCODE = 'NONE'
      #xml = Xbuilder.new
      #xml.p("\xE2\x80\x99")
      #assert_match(%r(<p>&#8217;</p>), xml.target!) #
    #end

    #def test_use_entities_if_encoding_is_utf_but_kcode_is_not
      #$KCODE = 'NONE'
      #xml = Xbuilder.new
      #xml.instruct!(:xml, :encoding => 'UTF-8')
      #xml.p("\xE2\x80\x99")
      #assert_match(%r(<p>&#8217;</p>), xml.target!) #
    #end
  #else
    ## change in behavior.  As there is no $KCODE anymore, the default
    ## moves from "does not understand utf-8" to "supports utf-8".

    #def test_use_entities_if_no_encoding_is_given_and_kcode_is_none
      #xml = Xbuilder.new
      #xml.p("\xE2\x80\x99")
      #assert_match("<p>\u2019</p>", xml.target!) #
    #end

    #def test_use_entities_if_encoding_is_utf_but_kcode_is_not
      #xml = Xbuilder.new
      #xml.instruct!(:xml, :encoding => 'UTF-8')
      #xml.p("\xE2\x80\x99")
      #assert_match("<p>\u2019</p>", xml.target!) #
    #end
  #end

  #def encode string, encoding
    #if !String.method_defined?(:encode)
      #$KCODE = encoding
      #string
    #elsif encoding == 'UTF8'
      #string.force_encoding('UTF-8')
    #else
      #string
    #end
  #end

  #def test_use_entities_if_kcode_is_utf_but_encoding_is_something_else
    #xml = Xbuilder.new
    #xml.instruct!(:xml, :encoding => 'UTF-16')
    #xml.p(encode("\xE2\x80\x99", 'UTF8'))
    #assert_match(%r(<p>&#8217;</p>), xml.target!) #
  #end

  #def test_use_utf8_if_encoding_defaults_and_kcode_is_utf8
    #xml = Xbuilder.new
    #xml.p(encode("\xE2\x80\x99",'UTF8'))
    #assert_equal encode("<p>\xE2\x80\x99</p>",'UTF8'), xml.target!
  #end

  #def test_use_utf8_if_both_encoding_and_kcode_are_utf8
    #xml = Xbuilder.new
    #xml.instruct!(:xml, :encoding => 'UTF-8')
    #xml.p(encode("\xE2\x80\x99",'UTF8'))
    #assert_match encode("<p>\xE2\x80\x99</p>",'UTF8'), xml.target!
  #end

  #def test_use_utf8_if_both_encoding_and_kcode_are_utf8_with_lowercase
    #xml = Xbuilder.new
    #xml.instruct!(:xml, :encoding => 'utf-8')
    #xml.p(encode("\xE2\x80\x99",'UTF8'))
    #assert_match encode("<p>\xE2\x80\x99</p>",'UTF8'), xml.target!
  #end
#end
