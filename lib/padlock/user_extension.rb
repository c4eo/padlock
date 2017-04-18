module Padlock
  module UserExtension
    extend ActiveSupport::Concern

    module ClassMethods
      def acts_as_padlock_user(opts={})
        Padlock.config.user_class_name  = self.name
        Padlock.config.user_foreign_key = opts[:foreign_key] if opts[:foreign_key].present?

        include Padlock::User
        # include Padlock::UserExtension::LocalInstanceMethods
      end
    end
  end
end
