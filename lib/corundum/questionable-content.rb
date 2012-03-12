require 'mattock/tasklib'

module Corundum
  class QuestionableContent < Mattock::Tasklib
    default_namespace :content
    setting :type, :debugging
    settings :words => ["p", "debugger"], :limit => 0 #ok
    setting :comments, false
    setting :accept_token, /#ok/
    setting :files

    def default_configuration(core)
      self.files = core.file_lists.code
    end

    def define
      in_namespace do
        task type do
          word_regexp = %r{#{words.map{|word| "\\b#{word}\\b"}.join("|")}}
          line_regexp = comments ? %r{\A\s*#.*#{word_regexp}} : word_regexp
          unless accept_token.nil?
            line_regexp = /#{line_regexp}(?:.(?!#{accept_token}))*\s*\Z/

          end

          found_words = Hash.new do |h,k|
            h[k] = 0
          end

          files_with_words = Hash.new do |h,k|
            h[k] = {}
          end


          files.each do |filename|
            File::open(filename) do |file|
              file.grep(line_regexp) do |line|
                line.scan(word_regexp) do |word|
                  files_with_words[filename][word] = true
                  found_words[word] += 1
                end
              end
            end
          end

          total = found_words.values.inject{|acc, num| acc + num} || 0

          if total > limit
            require 'pp'
            report = PP::pp([files_with_words, found_words], "")
            fail "Exceeded limits on words: #{words.join(",")}.  Full report:\n#{report}"
          end
        end
      end
      task :qa => in_namespace(type)
    end
  end
end
