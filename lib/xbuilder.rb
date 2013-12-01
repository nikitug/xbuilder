require 'blankslate'
require 'libxml'

# == Usage
#
# Xbuilder supports almost all of the Builder's features. Here is a small example:
#
#   xml = Xbuilder.new(indent: 2)
#   xml.node attr: 1 do |xml|     #=> <node attr="1">
#     xml.ns :child, attr: 2      #=>   <ns:child attr="2"/>
#   end                           #=> </node>
class Xbuilder < BlankSlate
  XML = ::LibXML::XML #:nodoc:
  define_method(:__class, find_hidden_method(:class))

  # Create an XML builder. Available options are:
  #
  # :root::
  #   Root element. All nodes created by the builder will be attached to it.
  #
  # :encoding::
  #   Document encoding, e.g. "UTF-8".
  #   Will be used in XML instruction: <tt><?xml version="1.0" encoding="UTF-8"?></tt>
  #
  # Builder compatibility options:
  # :indent:: Number of spaces used for indentation. Default is 0.
  # :margin:: Amount of initial indentation (specified in levels, not spaces).
  def initialize(options = {})
    if options[:target]
      ::Kernel.raise ::ArgumentError, "':target' option is not supported."
    end

    @indent = options[:indent].to_i
    @margin = options[:margin].to_i
    @root = options[:root] || XML::Document.new
    @encoding = options[:encoding] || "UTF-8"
  end

  # Append a tag with the method's name to the output.
  #   xml.node { |xml| xml.child } #=> <node><child/></node>
  def method_missing(name, *args, &block)
    name = "#{name}:#{args.shift}" if args.first.kind_of?(::Symbol)
    node = XML::Node.new(name.to_s)
    text = nil

    args.each do |arg|
      case arg
      when ::Hash
        arg.each do |key, val|
          k = key.to_s
          v = val.to_s
          node[k] = v
        end
      else
        text ||= ''
        text << arg.to_s
      end
    end

    if block && text
      ::Kernel.raise ::ArgumentError, "Cannot mix a text argument with a block"
    end

    node.content = text if text

    if block
      unless block.arity > 0
        ::Kernel.raise ::ArgumentError, "Provide at least 1 block argument: `xml.node { |xml| xml.child }'"
      end
      block.call(__new_instance(root: node))
    end

    __append_node(node)
  end

  # Append a tag to the output. The first argument is a tag name.
  # The rest of arguments are the same as <tt>method_missing</tt> ones.
  #   xml.tag!("node") { |xml| xml.tag!("child") } #=> <node><child/></node>
  def tag!(name, *args, &block)
    method_missing(name, *args, &block)
  end

  # Append text to the output. Escape by default.
  #
  #   xml.node { xml.text!("escaped & text") } #=> <node>escaped &amp; text</node>
  def text!(text, escape = true)
    __ensure_no_block(::Kernel.block_given?)
    node = XML::Node.new_text(text)
    node.output_escaping = escape
    __append_node(node)
  end

  # Append text to the output. Do not escape by default.
  #   xml.node { xml << "unescaped & text" } #=> <node>unescaped & text</node>
  def <<(text, escape = false)
    __ensure_no_block(::Kernel.block_given?)
    text!(text, escape)
  end

  # Returns the target XML string.
  def target!
    # FIXME Temp solution for encoding constant lookup.
    # (till bugfix release https://github.com/xml4r/libxml-ruby/pull/45 to be published)
    const_name = @encoding.upcase.gsub!("-", "_")
    encoding = XML::Encoding.const_get(const_name)

    XML.indent_tree_output = (@indent > 0)
    XML.default_tree_indent_string = (" " * @indent)

    @root.to_s(encoding: encoding, indent: XML.indent_tree_output).tap do |xml|
      if @margin > 0
        xml.gsub!(/^/, (" " * @indent) * @margin)
      end
    end
  end

  # Insert comment node.
  def comment!(comment_text)
    __ensure_no_block(::Kernel.block_given?)
    node = XML::Node.new_comment(comment_text)
    __append_node(node)
  end

  # XML declarations are not yet supported.
  def declare!(inst, *args, &block)
    __warn("XML declarations are not yet supported. Pull requests are welcome!")
  end

  # Custom XML instructions are not supported.
  # Left here for Builder API compatibility.
  def instruct!(*args)
    # TODO should we switch XML instruction off if `instruct!` is not called?
    __warn("Custom XML instructions are not supported")
  end

  # Insert CDATA node.
  def cdata!(text)
    __ensure_no_block(::Kernel.block_given?)
    node = XML::Node.new_cdata(text)
    __append_node(node)
  end

  private

  def __append_node(node)
    if @root.kind_of?(XML::Document)
      @root.root = node
    else
      @root << node
    end
  end

  def __new_instance(root)
    __class.new(root)
  end

  def __ensure_no_block(given)
    if given
      ::Kernel.raise ArgumentError.new("Blocks are not allowed on XML instructions")
    end
  end

  def __warn(msg)
    ::Kernel.warn("Xbuilder WARNING: #{msg}")
  end

end

require "xbuilder/template" if defined?(ActionView::Template)
