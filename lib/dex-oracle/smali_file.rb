# encoding: utf-8
require_relative 'smali_field'
require_relative 'smali_method'
require_relative 'logging'

class SmaliFile
  attr_reader :class, :super, :interfaces, :methods, :fields, :file_path, :content

  include Logging

  ACCESSOR = /(?:abstract|annotation|constructor|enum|final|interface|native|private|protected|public|static|strictfp|synchronized|synthetic|transient|volatile|varargs)/
  TYPE = /(?:[IJFDZBCV]|L[^;]+;)/
  CLASS = /^\.class (?:#{ACCESSOR} )*(L[^;]+;)/
  SUPER = /^\.super (L[^;]+;)/
  INTERFACE = /^\.implements (L[^;]+;)/
  FIELD = /^\.field (?:#{ACCESSOR} )+([^\s]+)$/
  METHOD = /^\.method (?:#{ACCESSOR} )+([^\s]+)$/

  def initialize(file_path)
    @file_path = file_path
    @modified = false
    parse(file_path)
  end

  def update
    @methods.each do |m|
      next unless m.modified
      logger.debug("Updating method: #{m}")
      update_method(m)
      m.modified = false
    end
    File.open(@file_path, 'w') { |f| f.write(@content) }
  end

  def to_s
    @class
  end

  private

  def parse(file_path)
    logger.debug("Parsing: #{file_path} ...")
    @content = File.open(file_path, 'r:UTF-8', &:read)
    @class = @content[CLASS, 1]
    @super = @content[SUPER, 1]
    @interfaces = []
    @content.scan(INTERFACE).each { |m| @interfaces << m.first }
    @fields = []
    @content.scan(FIELD).each { |m| @fields << SmaliField.new(@class, m.first) }
    parse_methods
  end

  def parse_methods
    @methods = []
    method_signature = nil
    in_method = false
    body = nil
    @content.each_line do |line|
      if in_method
        if /^\.end method$/ =~ line
          in_method = false
          @methods << SmaliMethod.new(@class, method_signature, body)
          next
        end
        body << line
      else
        next unless line.include?('.method ')
        m = METHOD.match(line)
        next unless m

        in_method = true
        method_signature = m.captures.first
        body = "\n"
      end
    end
  end

  def build_method_regex(method_signature)
    /^\.method (?:#{ACCESSOR} )+#{Regexp.escape(method_signature)}(.+?)^\.end method$/m
  end

  def update_method(method)
    body_regex = build_method_regex(method.signature)
    @content[body_regex, 1] = method.body
  end
end
