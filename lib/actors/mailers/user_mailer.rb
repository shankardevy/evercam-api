module Evercam
  module Mailers
    class UserMailer < Mailer

      def confirm
        {
          to: user.email,
          subject: 'Evercam Confirmation',
          html_body: erb('templates/emails/user/confirm.html.txt'),
          body: erb('templates/emails/user/confirm.txt')
        }
      end

      def interested
        {
          to: 'signups@evercam.io',
          subject: 'Signup on evercam.io',
          body: erb('templates/emails/user/interested.txt')
        }
      end

      def app_idea
        {
          to: 'garrett@evercam.io',
          subject: 'Marketplace idea on evercam.io',
          body: erb('templates/emails/user/app_idea.txt')
        }
      end

    end
  end
end

