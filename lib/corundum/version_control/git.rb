require 'corundum/version_control'

module Corundum
  class Git < VersionControl
    setting(:branch, nil)

    def resolve_configuration
      @branch ||= guess_branch
    end

    def git_command(*args)
      result = Mattock::CommandLine.new("git", "--no-pager") do |cmd|
        args.each do |arg|
          cmd.options += [*arg]
        end
      end.run
      result.must_succeed!
      result.stdout
    end

    def guess_branch
      puts "Guessing branch - configure Git > branch"
      branch = git_command("branch").grep(/^\*/).first.sub(/\*\s*/,"").chomp
      puts "  Guessed: #{branch}"
      return branch
    end

    def define
      super

      in_namespace do
        task :on_branch do
          current_branch = git_command("branch").grep(/^\*/).first.sub(/\*\s*/,"").chomp
          unless current_branch == branch
            fail "Current branch \"#{current_branch}\" is not #{branch}"
          end
        end

        task :not_tagged => :on_branch do
          tags = git_command("tag", "-l", tag)
          unless tags.empty?
            fail "Tag #{tag} already exists in branch #{branch}"
          end
        end

        task :workspace_committed => :on_branch do
          diffs = git_command("diff", "--stat", "HEAD")
          unless diffs.empty?
            fail "Workspace not committed:\n  #{diffs.join("  \n")}"
          end
        end

        task :gemspec_files_added => :on_branch do
          list = git_command(%w{ls-tree -r HEAD})
          list.map! do |line|
            line.split(/\s+/)[3]
          end

          missing = gemspec_files - list
          unless missing.empty?
            fail "Gemspec files not in version control: #{missing.join(", ")}"
          end
        end

        task :is_pulled do
          fetch = git_command("fetch", "--dry-run")
          unless fetch.empty?
            fail "Remote branch has unpulled changes"
          end

          remote = git_command("config", "--get", "branch.#{branch}.remote").first
          merge = git_command("config", "--get", "branch.#{branch}.merge").first.split("/").last

          ancestor = git_command("merge-base", branch, "#{remote}/#{merge}").first
          remote_rev = File::read(".git/refs/remotes/#{remote}/#{merge}").chomp

          unless ancestor == remote_rev
            fail "Unmerged changes with remote branch #{remote}/#{merge}"
          end
        end
        task :is_checked_in => :is_pulled

        task :tag => :on_branch do
          git_command("tag", tag)
        end

        task :push => :on_branch do
          git_command("push")
        end

        task :check_in => [:push]
      end
    end
  end
end
