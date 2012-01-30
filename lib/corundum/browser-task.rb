require 'mattock/command-task'

module Corundum
  class BrowserTask < Mattock::CommandTask
    setting(:browser, "chromium")
    setting(:index_html)
    setting(:task_name, "view")

    def default_configuration(parent)
      self.browser = parent.browser
    end

    def task_args
      [{task_name => index_html}]
    end

    def resolve_configuration
      self.command = Mattock::CommandLine.new(browser, index_html)
    end
  end
end
