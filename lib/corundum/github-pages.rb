require 'corundum/tasklib'
require 'mattock/task'

module Corundum
  class GitTask < Mattock::CommandTask
    setting(:subcommand)
    setting(:arguments, [])

    def command
      Mattock::CommandLine.new("git", "--no-pager") do |cmd|
        cmd.options << subcommand
        arguments.each do |arg|
          cmd.options += [*arg]
        end
      end
    end
  end

  class InDirCommandTask < Mattock::CommandTask
    setting :directory
    def action
      FileUtils.cd directory do
        super
      end
    end
  end

  class GithubPages < TaskLib
    default_namespace :publish_docs

    setting(:pub_dir)

    def branch
      "gh-pages"
    end

    def default_configuration(doc_gen)
      self.pub_dir = "publish"
    end

    def git_command(*args)
      Mattock::CommandLine.new("git", "--no-pager") do |cmd|
        args.each do |arg|
          cmd.options += [*arg]
        end
      end
    end

    def git(*args)
      result = git_command(*args).run
      result.must_succeed!
      result.stdout.lines.to_a
    end

    $verbose = true

    def define
      in_namespace do
        file File::join(pub_dir, ".git") do
          fail "Refusing to clobber existing #{pub_dir}" if File.exists?(pub_dir)

          url = git("config", "--get", "remote.origin.url").first

          Mattock::PrereqChain.new do |chain|
            chain.add git_command("clone", ".git", pub_dir)
            chain.add git_command("config -f", pub_dir + "/.git/config", "--replace-all remote.origin.url", url)
          end.must_succeed!
        end

        InDirCommandTask.new() do |t|
          t.task_name = :setup
          t.directory = pub_dir
          t.verify_command = Mattock::PipelineChain.new do |chain|
            chain.add git_command(%w{branch -r})
            chain.add Mattock::CommandLine.new("grep", "-q", branch)
          end
          t.command = Mattock::PrereqChain.new do |cmd|
            cmd.add git_command("checkout", "-b", branch)
            cmd.add Mattock::CommandLine.new("rm -rf *")
            cmd.add git_command(%w{commit -a -m} + ["'Creating pages'"])
            cmd.add git_command("push", "origin", branch)
            cmd.add git_command("branch", "--set-upstream", branch, "origin/" + branch)
          end
        end
        task :setup => File::join(pub_dir, ".git")

        task :on_branch do
          FileUtils.cd pub_dir do
            current_branch = git("branch").grep(/^\*/).first.sub(/\*\s*/,"").chomp
            unless current_branch == branch
              fail "Current branch \"#{current_branch}\" is not #{branch}"
            end
          end
        end

        task :workspace_committed => :on_branch do
          FileUtils.cd pub_dir do
            diffs = git("diff", "--stat", "HEAD")
            unless diffs.empty?
              fail "Workspace not committed:\n  #{diffs.join("  \n")}"
            end
          end
        end

        task :is_pulled do
          FileUtils.cd do
            fetch = git("fetch", "--dry-run")
            unless fetch.empty?
              fail "Remote branch has unpulled changes"
            end

            remote = git("config", "--get", "branch.#{branch}.remote").first
            merge = git("config", "--get", "branch.#{branch}.merge").first.split("/").last

            ancestor = git("merge-base", branch, "#{remote}/#{merge}").first
            remote_rev = File::read(".git/refs/remotes/#{remote}/#{merge}").chomp

            unless ancestor == remote_rev
              fail "Unmerged changes with remote branch #{remote}/#{merge}"
            end
          end
        end
        task :is_checked_in => :is_pulled

        task :push => :on_branch do
          FileUtils.cd pub_dir do
            git("push", "origin", "gh-pages")
          end
        end

        task :check_in => [:push]
      end

      file pub_dir => self[:setup]
      task :preflight => self[:is_checked_in]

      desc "Push documentation files to Github Pages"
      task root_task => self[:check_in]
    end
  end
end
