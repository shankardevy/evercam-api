require_relative 'mailer'

module Evercam
  module Mailers
    class UserMailer < Mailer

      def confirm
        {
          to: user.email,
          subject: 'Evercam Confirmation',
          html_body: erb('templates/emails/user/confirm.html.erb'),
          body: erb('templates/emails/user/confirm.txt')
        }
      end

      def share
        {
          to: email,
          subject: "#{user.fullname} has shared a camera with you",
          html_body: erb('templates/emails/user/camera_shared_notification.html.erb'),
          attachments: attachments
        }
      end

      def share_request
        {
          to: email,
          subject: "#{user.fullname} has shared a camera with you",
          html_body: erb('templates/emails/user/sign_up_to_share_email.html.erb'),
          attachments: attachments
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

