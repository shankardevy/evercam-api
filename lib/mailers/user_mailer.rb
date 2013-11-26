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

    end
  end
end

