require 'mattock/tasklib'

module Corundum
  class Email < Mattock::TaskLib
    default_namespace :email

    setting(:rubyforge)
    setting(:email_servers, [])
    setting(:gemspec)
    setting(:announce_to_email, nil)
    setting(:urls, nested.required_fields(:home_page, :project_page))

    def default_configuration(toolkit)
      self.rubyforge = toolkit.rubyforge
      self.gemspec = toolkit.gemspec
      self.urls.home_page = toolkit.gemspec.homepage
      self.urls.project_page = toolkit.rubyforge.project_page
    end

    def announcement
      changes = ""
      begin
        File::open("./Changelog", "r") do |changelog|
          changes = "Changes:\n\n"
          changes += changelog.read
        end
      rescue Exception
      end

      urls = "Project: #{urls.project_page}\n" +
      "Homepage: #{urls.home_page}"

      subject = "#{gemspec.name} #{gemspec.version} Released"
      title = "#{gemspec.name} version #{gemspec.version} has been released!"
      body = "#{gemspec.description}\n\n#{changes}\n\n#{urls}"

      return subject, title, body
    end

    def define
      desc 'Announce release on email'
      task root_task => in_namespace("rubyforge", "email")
      in_namespace do
        file "email.txt" do |t|
          require 'mailfactory'

          subject, title, body= announcement

          mail = MailFactory.new
          mail.To = announce_to_email
          mail.From = gemspec.email
          mail.Subject = "[ANN] " + subject
          mail.text = [title, body].join("\n\n")

          File.open(t.name, "w") do |mailfile|
            mailfile.write mail.to_s
          end
        end

        task :email => "email.txt" do
          require 'net/smtp'

          email_servers.each do |server_config|
            begin
              File::open("email.txt", "r") do |email|
                Net::SMTP.start(server_config[:server], 25, server_config[:helo], server_config[:username], server_config[:password]) do |smtp|
                  smtp.data do |mta|
                    mta.write(email.read)
                  end
                end
              end
              break
            rescue Object => ex
              puts ex.message
            end
          end
        end
      end
    end
  end
end
