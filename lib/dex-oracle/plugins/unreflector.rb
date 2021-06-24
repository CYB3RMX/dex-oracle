require 'digest'
require_relative '../logging'

class Unreflector < Plugin
  attr_reader :optimizations

  include Logging
  include CommonRegex

  CLASS_FOR_NAME = 'invoke-static \{[vp]\d+\}, Ljava\/lang\/Class;->forName\(Ljava\/lang\/String;\)Ljava\/lang\/Class;'.freeze
  CLASS_FOR_NAME_2 = 'invoke-static\/range {[vp]\d+ .. [vp]\d+}, Ljava\/lang\/Class;->forName\(Ljava\/lang\/String;\)Ljava\/lang\/Class;'.freeze

  CONST_CLASS_REGEX = Regexp.new(
    '^[ \t]*(' +
    CONST_STRING + '\s+' +
    CLASS_FOR_NAME + '\s+' +
    MOVE_RESULT_OBJECT + ')'
  )
  CONST_CLASS_REGEX_2 = Regexp.new(
    '^[ \t]*(' +
    CONST_STRING + '\s+' +
    CLASS_FOR_NAME_2 + '\s+' +
    MOVE_RESULT_OBJECT + ')'
  )
  VIRTUAL_FIELD_LOOKUP = Regexp.new(
    '^[ \t]*(' +
    CONST_STRING + '\s+' \
    'invoke-static \{[vp]\d+\}, Ljava\/lang\/Class;->forName\(Ljava\/lang\/String;\)Ljava\/lang\/Class;\s+' +
    MOVE_RESULT_OBJECT + '\s+' +
    CONST_STRING + '\s+' \
    'invoke-virtual \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/Class;->getField\(Ljava\/lang\/String;\)Ljava\/lang\/reflect\/Field;\s+' +
    MOVE_RESULT_OBJECT + '\s+' \
    'invoke-virtual \{[vp]\d+, ([vp]\d+)\}, Ljava\/lang\/reflect\/Field;->get\(Ljava\/lang\/Object;\)Ljava\/lang\/Object;\s+' +
    MOVE_RESULT_OBJECT + ')'
  )

  STATIC_FIELD_LOOKUP = Regexp.new(
    '^[ \t]*(' +
    CONST_STRING + '\s+' +
    CLASS_FOR_NAME + '\s+' +
    MOVE_RESULT_OBJECT + '\s+' +
    CONST_STRING +
    'invoke-virtual \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/Class;->getField\(Ljava\/lang\/String;\)Ljava\/lang\/reflect\/Field;\s+' +
    MOVE_RESULT_OBJECT + '\s+' \
    'const/4 [vp]\d+, 0x0\s+' \
    'invoke-virtual \{[vp]\d+, ([vp]\d+)\}, Ljava\/lang\/reflect\/Field;->get\(Ljava\/lang\/Object;\)Ljava\/lang\/Object;\s+' +
    MOVE_RESULT_OBJECT +
    ')'
  )

  CLASS_LOOKUP_MODIFIER = -> (_, output, out_reg) { "const-class #{out_reg}, #{output}" }

  def initialize(driver, smali_files, methods)
    @driver = driver
    @smali_files = smali_files
    @methods = methods
    @optimizations = Hash.new(0)
  end

  def process
    made_changes = false
    @methods.each do |method|
      logger.info("Unreflecting #{method.descriptor}")
      made_changes |= lookup_classes(method)
    end

    made_changes
  end

  private

  def lookup_classes(method)
    target_to_contexts = {}
    target_id_to_output = {}
    matches = method.body.scan(CONST_CLASS_REGEX)
    matches += method.body.scan(CONST_CLASS_REGEX_2)
    matches.each do |original, class_name, out_reg|
      if class_name == "[B"
        next
      else
        
        target = { id: Digest::SHA256.hexdigest(original) }
        smali_class = "L#{class_name.tr('.', '/')};"
        logger.info(original + ";"+ smali_class + ";" + class_name)
        target_id_to_output[target[:id]] = ['success', smali_class]
        target_to_contexts[target] = [] unless target_to_contexts.key?(target)
        target_to_contexts[target] << [original, out_reg]
        @optimizations[:class_lookups] += 1
      end
    end

    method_to_target_to_contexts = { method => target_to_contexts }
    Plugin.apply_outputs(target_id_to_output, method_to_target_to_contexts, CLASS_LOOKUP_MODIFIER)
  end
end
