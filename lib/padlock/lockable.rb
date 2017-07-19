module Padlock
  module Lockable
    extend ActiveSupport::Concern

    included do
      has_one :padlock, class_name: "Padlock::Instance", as: :lockable
      has_one :padlock_user, through: :padlock, source: :user
    end

    def locked?
      self.padlock.present?
    end

    def unlocked?
      !self.locked?
    end

    def locked_by
      self.padlock.user if self.locked?
    end

    def locked_by? user
      locked_by == user
    end

    def lock_touched_at
      self.padlock.updated_at if self.locked?
    end

    def unlock!
      self.padlock.destroy if self.locked?
    end
  end
end
