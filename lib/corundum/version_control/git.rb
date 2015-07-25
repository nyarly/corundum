require 'corundum/version_control'
require 'erb'

module Corundum
  class Git < VersionControl
    setting(:branch, nil)
    setting(:build_finished_task)

    def default_configuration(toolkit)
      super
      self.build_finished_task = toolkit.build_file.abspath
    end

    def resolve_configuration
      super
      @branch ||= guess_branch
    end

    def git_command(*args)
      cmd("git", "--no-pager") do |cmd|
        args.each do |arg|
          cmd.options += [*arg]
        end
      end
    end

    def git(*args)
      result = git_command(*args).run
      result.must_succeed!
      return result.stdout.lines.to_a
    end

    def guess_branch
      puts "Guessing branch - configure Git > branch"
      branch = git("branch").grep(/^\*/).first.sub(/\*\s*/,"").chomp
      puts "  Guessed: #{branch}"
      return branch
    end

    def define
      super

      in_namespace do
        task :on_branch do
          current_branch = git("branch").grep(/^\*/).first.sub(/\*\s*/,"").chomp
          unless current_branch == branch
            fail "Current branch \"#{current_branch}\" is not #{branch}"
          end
        end

        task :not_tagged => :on_branch do
          tags = git("tag", "-l", tag)
          unless tags.empty?
            fail "Tag #{tag} already exists in branch #{branch}"
          end
        end

        task :workspace_committed => :on_branch do
          diffs = git("diff", "--stat", "HEAD")
          unless diffs.empty?
            fail "Workspace not committed:\n  #{diffs.join("  \n")}"
          end
        end

        task :gemspec_files_added => :on_branch do
          list = git(%w{ls-tree -r HEAD})
          list.map! do |line|
            line.split(/\s+/)[3]
          end

          missing = gemspec_files - list
          unless missing.empty?
            fail "Gemspec files not in version control: #{missing.join(", ")}"
          end
        end

        task :is_pulled do
          fetch = git("fetch", "--dry-run")
          unless fetch.empty?
            fail "Remote branch has unpulled changes"
          end

          remote = git("config", "--get", "branch.#{branch}.remote").first.chomp
          merge = git("config", "--get", "branch.#{branch}.merge").first.split("/").last.chomp

          ancestor = git("merge-base", branch, "#{remote}/#{merge}").first.chomp
          remote_rev = git("ls-remote", remote, merge).first.split(/\s+/).first

          unless ancestor == remote_rev
            fail "Unmerged changes with remote branch #{remote}/#{merge}\n#{ancestor.inspect}\n#{remote_rev.inspect}"
          end
        end
        task :is_checked_in => :is_pulled

        task :tag => :on_branch do
          git("tag", tag)
        end

        task :push => :on_branch do
          git("push", "--tags")
        end

        task :check_in => [:push]
      end
      file build_finished_task => in_namespace("is_checked_in")
    end
  end
end
