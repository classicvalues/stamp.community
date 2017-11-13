module Votable
  module State
    extend ActiveSupport::Concern

    included do
      state_machine initial: :in_progress do
        transition in_progress: :accepted, on: :accept
        transition in_progress: :denied, on: :deny
        transition %i[accepted denied] => :archived, on: :archive
        transition %i[accepted denied] => :overruled, on: :overrule
      end
    end
  end
end
