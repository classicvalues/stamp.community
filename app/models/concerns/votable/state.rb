module Votable
  module State
    extend ActiveSupport::Concern

    included do
      after_create :schedule!

      scope :accepted, -> { with_state(:accepted) }
      scope :archived, -> { with_state(:archived) }
      scope :denied, -> { with_state(:denied) }
      scope :disputed, -> { with_state(:disputed) }
      scope :in_progress, -> { with_state(:in_progress) }

      state_machine initial: :in_progress, use_transactions: true do
        transition in_progress: :accepted, on: :accept
        transition in_progress: :denied, on: :deny
        # controversy: a discussion of opposing opinions
        # dispute: a failure to agree
        # for now: dispute, since we do not re-enact stamps into a second round
        transition in_progress: :disputed, on: :dispute
        transition accepted: :archived, on: :archive

        before_transition in_progress: :accepted do |votable, _|
          votable.archive_accepted_siblings!
        end

        before_transition do |votable, transition|
          votable.create_system_activity(
            key: votable.key_for(action: transition.to_name),
            recipient: votable.stampable
          )
        end
      end
    end

    def scheduled_at
      created_at + ENVProxy.required_integer('STAMP_CONCLUDE_IN_HOURS').hours
    end

    def schedule!
      return nil if scheduled_job.present? || !in_progress?

      Votable::ConcludeWorker.perform_in(
        scheduled_at.to_i,
        self.class.name,
        id
      )
    end

    def scheduled_job
      return nil unless in_progress?

      Sidekiq::ScheduledSet.new.select do |scheduled|
        scheduled.klass == 'Votable::ConcludeWorker' &&
          scheduled.args[0] == self.class.name &&
          scheduled.args[1] == id
      end.first
    end

    def archive_accepted_siblings!
      siblings.accepted.each(&:archive!)
    end
  end
end
