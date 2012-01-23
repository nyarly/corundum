require 'corundum/version_control'
require 'strscan'

module Corundum
  class Monotone < VersionControl

    setting(:branch, nil)

    def resolve_configuration
      @branch ||= guess_branch
    end

    def mtn_automate(cmd, *args)
      result = Mattock::CommandLine.new("mtn", "automate", cmd) do |cmd|
        cmd.options += args
      end.run
      result.must_succeed!
      result.stdout
    end

    def parse_basic_io(string)
      items = []
      scanner = StringScanner.new(string)
      scanner.scan(/\s*/m)
      until scanner.eos? do

        symbol = scanner.scan(/[a-z_]*/)
        scanner.scan(/\s*/)
        value = ""
        case scanner.scan(/["\[]/)
        when '"'
          while (value += scanner.scan(/[^"]*/)) =~ /\\$/
          end
          scanner.scan(/"/)
        when '['
          value = scanner.scan(/[^\]]*/)
          scanner.scan(/]/)
        else
          raise "Improperly formatted basic_io: \
            \n  Got: #{items.inspect} + #{symbol}\
            \n  Rest:\
            \n    #{scanner.rest}"
        end
        items << [symbol, value]
        scanner.scan(/\s*/m)
      end
      return items
    end

    def parse_certs(string)
      items = parse_basic_io(string)
      pair = []
      hash = Hash.new do |h,k|
        h[k] = []
      end
      items.each do |name, value|
        case name
        when "name"
          pair[0] = value
        when "value"
          pair[1] = value
        when "trust"
          if value == "trusted"
            hash[pair[0]] << pair[1]
          end
          pair = []
        end
      end
      hash
    end

    def base_revision
      mtn_automate("get_base_revision_id").chomp
    end

    def guess_branch
      puts "Guessing branch - configure Monotone > branch"
      certs = parse_certs(mtn_automate("certs", base_revision))
      puts "  Guessed: #{certs["branch"].first}"
      certs["branch"].first
    end



    def stanzas(first_item, items)
      stanzas = []
      current_stanza = {}
      items.each do |name, value|
        if name == first_item
          current_stanza = {}
          stanzas << current_stanza
        end
        current_stanza[name] = value
      end
      return stanzas
    end

    def define
      super

      in_namespace do
        task :on_branch do
          branches = parse_certs(mtn_automate("certs", base_revision))["branch"] || []
          unless branches.include?(branch)
            fail "Not on branch #{branch}"
          end
        end

        task :not_tagged do
          items = parse_basic_io(mtn_automate("tags", branch))
          tags = items.find{|pair| pair[0] == "tag" && pair[1] == tag}
          unless tags.nil?
            fail "Tag #{tag} already exists in branch #{branch}"
          end
        end

        task :workspace_committed => :on_branch do
          items = parse_basic_io(mtn_automate("inventory"))
          changed = items.find{|pair| pair[0] == "changes"}
          unless changed.nil?
            fail "Uncommitted changes exist in workspace"
          end
        end

        task :gemspec_files_added => :on_branch do
          items = stanzas("path", parse_basic_io(mtn_automate("inventory")))
          items.delete_if{|item| item["status"] == "unknown"}
          known_paths = items.each_with_object({}) do |item, hash|
            hash[item["path"]] = true
          end

          files = gemspec_files.dup
          files.delete_if{|path| known_paths[path]}
          unless files.empty?
            fail "Gemspec files not in version control: #{files.join(" ")}"
          end
        end

        task :tag => :on_branch do
          mtn_automate("cert", base_revision, "tag", tag)
        end

        task :sync do
          mtn_automate("sync")
        end

        task :check_in => [:sync]
      end
    end
  end
end
