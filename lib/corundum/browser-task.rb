require 'mattock/command-task'

module Corundum
  class BrowserTask < Mattock::Rake::CommandTask
    setting(:browser, "chromium")
    setting(:index_html)
    setting(:task_name, "view")

    def default_configuration(parent)
      super
      self.browser = parent.browser
    end

    def task_args
      [{task_name => index_html}]
    end

    def resolve_configuration
      super
      self.command = Mattock::CommandLine.new(browser, index_html)
    end
  end
end
