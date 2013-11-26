require 'mattock/tasklib'

module Corundum
  class QuestionableContent < Mattock::Tasklib
    #I hate putting these lists together. I have to keep reminding myself that
    #it's akin to discussing the use of the word.
    #Also, this is a place I'm especially open to contributions.
    WORD_SETS = {
      "debug" => ["p", "debugger"], #ok
      "profanity" => ['fuck\w*', 'shit\w*'], #ok
      "ableism" => ["crazy", '\w*sanity', "dumb", 'idiot\w*', "lame", 'moron\w*', "retarded"], #ok
      "racism" => ["chink", "coon", "dago", "gook", 'gyp\w*', "k[yi]ke", 'nig\w*', "spic"], #ok
      "gender" => ["bitch", "cocksucker", "cunt", "dyke", "faggot", "tranny"], #ok
      "issues" => ["XXX", "TODO"], #ok
    }
    [
      ["debug", "debugging"],
      ["profanity", "swearing"],
      ["profanity", "swears"],
      ["ableism", "ablism"],
      ["racism", "ethnic"],
      ["gender", "sexism"]
    ].each do |name, other|
      WORD_SETS[other] = WORD_SETS[name]
    end

    default_namespace :content
    setting :type, :debugging
    setting :words
    setting :limit, 0
    setting :comments, false
    setting :accept_token, /#ok/
    setting :files
    setting :qa_rejections

    def default_configuration(core)
      super
      core.copy_settings_to(self)
      self.files = core.file_lists.code
      self.qa_rejections = core.qa_rejections
    end

    def resolve_configuration
      if field_unset?(:words)
        self.words = WORD_SETS.fetch(type.to_s) do
          raise "Word set #{type.inspect} unknown. Choose from: #{WORD_SETS.keys.inspect}"
        end
      end
      super
    end

    def define
      in_namespace do
        task type do |task|
          require 'corundum/qa-report'

          word_regexp = %r{(?i:#{words.map{|word| "\\b#{word}\\b"}.join("|")})}
          line_regexp = case comments
                        when true, :only
                          %r{\A\s*#.*#{word_regexp}}
                        when false, :both
                          word_regexp
                        when :ignore
                          %r{\A\s*[^#]*#{word_regexp}} #this will fail like "Stuff #{interp}" <word>
                        end

          unless accept_token.nil?
            line_regexp = /#{line_regexp}(?:.(?!#{accept_token}))*\s*\Z/
          end

          rejections = QA::Report.new("Content: #{type}")
          qa_rejections << rejections
          files.each do |filename|
            File::open(filename) do |file|
              file.each_line.with_index do |line, line_number|
                next unless line_regexp =~ line
                line.scan(word_regexp) do |word|
                  rejections << QA::Rejection.new(word, filename, line_number+1)
                end
              end
            end
          end

          if rejections.length > limit
            rejections.fail "Maximum allowed uses: #{limit}"
          end
        end
      end
      task :run_quality_assurance => in_namespace(type)
      task :run_continuous_integration => in_namespace(type)
    end
  end
end
