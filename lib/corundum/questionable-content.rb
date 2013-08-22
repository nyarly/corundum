require 'mattock/tasklib'

module Corundum
  class QuestionableContent < Mattock::Tasklib
    default_namespace :content
    setting :type, :debugging
    settings :words => ["p", "debugger"], :limit => 0 #ok
    setting :comments, false
    setting :accept_token, /#ok/
    setting :files
    setting :qa_rejections

    def default_configuration(core)
      super
      core.copy_settings_to(self)
      self.files = core.file_lists.code
    end

    def define
      in_namespace do
        task type do |task|
          require 'corundum/qa-report'

          word_regexp = %r{#{words.map{|word| "\\b#{word}\\b"}.join("|")}}
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
                  rejections << QA::Rejection.new(word, file, line_number+1)
                end
              end
            end
          end

          if rejections.length > limit
            rejections.fail "Maximum allowed uses: #{limit}"
          end
        end
      end
      task :qa => in_namespace(type)
    end
  end
end
