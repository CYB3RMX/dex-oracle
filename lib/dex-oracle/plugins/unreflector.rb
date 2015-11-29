require 'logger'

class Unreflector < Plugin
  CLASS_FOR_NAME = 'invoke-static \{[vp]\d+\}, Ljava\/lang\/Class;->forName\(Ljava\/lang\/String;\)Ljava\/lang\/Class;'

  CONST_CLASS_REGEX = Regexp.new(
      '^[ \t]*(' <<
          CommonRegex::CONST_STRING << '\s+' <<
          CLASS_FOR_NAME << '\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT <<
          ')')

  VIRTUAL_FIELD_LOOKUP = Regexp.new(
      '^[ \t]*(' <<
          CommonRegex::CONST_STRING << '\s+' <<
          'invoke-static \{[vp]\d+\}, Ljava\/lang\/Class;->forName\(Ljava\/lang\/String;\)Ljava\/lang\/Class;\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT << '\s+' <<
          CommonRegex::CONST_STRING << '\s+' <<
          'invoke-virtual \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/Class;->getField\(Ljava\/lang\/String;\)Ljava\/lang\/reflect\/Field;\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT << '\s+' <<
          'invoke-virtual \{[vp]\d+, ([vp]\d+)\}, Ljava\/lang\/reflect\/Field;->get\(Ljava\/lang\/Object;\)Ljava\/lang\/Object;\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT <<
          ')')

  STATIC_FIELD_LOOKUP = Regexp.new(
      '^[ \t]*(' <<
          CommonRegex::CONST_STRING << '\s+' <<
          CLASS_FOR_NAME << '\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT << '\s+' <<
          CommonRegex::CONST_STRING <<
          'invoke-virtual \{[vp]\d+, [vp]\d+\}, Ljava\/lang\/Class;->getField\(Ljava\/lang\/String;\)Ljava\/lang\/reflect\/Field;\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT << '\s+' <<
          'const/4 [vp]\d+, 0x0\s+' <<
          'invoke-virtual \{[vp]\d+, ([vp]\d+)\}, Ljava\/lang\/reflect\/Field;->get\(Ljava\/lang\/Object;\)Ljava\/lang\/Object;\s+' <<
          CommonRegex::MOVE_RESULT_OBJECT <<
          ')')

  def self.process(smali_file)
    @@logger = Logger.new(STDOUT)

    @@logger.debug("Unreflecting #{smali_file}")
  end

  private

  def self.decrypt_string(method_body)

  end
end
