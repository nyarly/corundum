require 'mattock/tasklib'
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
    setting :target_dir

    def default_configuration(parent)
      super
      parent.copy_settings_to(self)
    end

    def needed?
      return true unless File.directory? target_dir
      Dir.chdir target_dir do
        super
      end
    end

    def action
      Dir.chdir target_dir do
        super
      end
    end
  end

  class GithubPages < Mattock::TaskLib
    default_namespace :publish_docs

    setting(:target_dir, "gh-pages")
    setting(:source_dir)
    setting(:docs_index)

    nil_fields :repo_dir

    def branch
      "gh-pages"
    end

    def default_configuration(doc_gen)
      super
      self.source_dir = doc_gen.target_dir
      self.docs_index = doc_gen.entry_point
    end

    def resolve_configuration
      super
      self.repo_dir ||= File::join(target_dir, ".git")
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

    def define
      in_namespace do
        file repo_dir do
          fail "Refusing to clobber existing #{target_dir}" if File.exists?(target_dir)

          url = git("config", "--get", "remote.origin.url").first
          git("clone", url.chomp, target_dir)
        end

        InDirCommandTask.new(self, :remote_branch => repo_dir) do |t|
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

        InDirCommandTask.new(self, :local_branch => :remote_branch) do |t|
          t.verify_command = Mattock::PipelineChain.new do |chain|
            chain.add git_command(%w{branch})
            chain.add Mattock::CommandLine.new("grep", "-q", "'#{branch}'")
          end
          t.command = Mattock::PrereqChain.new do |chain|
            chain.add git_command("checkout", "-b", branch)
            chain.add git_command("branch", "--set-upstream", branch, "origin/" + branch)
            chain.add Mattock::CommandLine.new("rm", "-f", '.git/index')
            chain.add git_command("clean", "-fdx")
          end
        end

        InDirCommandTask.new(self, :on_branch => [:remote_branch, :local_branch]) do |t|
          t.verify_command = Mattock::PipelineChain.new do |chain|
            chain.add git_command(%w{branch})
            chain.add Mattock::CommandLine.new("grep", "-q", "'^[*] #{branch}'")
          end
          t.command = Mattock::PrereqChain.new do |chain|
            chain.add git_command("checkout", branch)
          end
        end

        task :pull => [repo_dir, :on_branch] do
          FileUtils.cd target_dir do
            git("pull", "-X", "ours")
          end
        end

        task :cleanup_repo => repo_dir do
          Mattock::CommandLine.new("rm", "-f", File::join(repo_dir, "hooks", "*")).must_succeed!
          File::open(File::join(repo_dir, ".gitignore"), "w") do |file|
            file.write ".sw?"
          end
        end

        file target_dir => [:on_branch, :cleanup_repo]

        task :pre_publish => [repo_dir, target_dir]

        task :clobber_target => [:on_branch, :pull] do
          Mattock::CommandLine.new(*%w{rm -rf}) do |cmd|
            cmd.options << target_dir + "/*"
          end.must_succeed!
        end

        task :assemble_docs => [docs_index, :pre_publish, :clobber_target] do
          Mattock::CommandLine.new(*%w{cp -a}) do |cmd|
            cmd.options << source_dir + "/*"
            cmd.options << target_dir
          end.must_succeed!
        end

        task :publish => [:assemble_docs, :on_branch] do
          FileUtils.cd target_dir do
            git("add", ".")
            git("commit", "-m", "'Corundum auto-publish'")
            git("push", "origin", branch)
          end
        end
      end

      desc "Push documentation files to Github Pages"
      task root_task => self[:publish]
    end
  end
end
