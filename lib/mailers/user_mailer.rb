module Evercam
  module Mailers
    class UserMailer < Mailer

      def confirm
        {
          to: user.email,
          subject: 'Evercam Confirmation',
          body: erb('user/confirm.txt')
        }
      end

      def interested
        {
          to: 'signups@evercam.io',
          subject: 'Signup on evercam.io',
          body: erb('user/interested.txt')
        }
      end

    end
  end
end

