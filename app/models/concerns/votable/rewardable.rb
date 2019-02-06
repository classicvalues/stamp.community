module Votable
  module Rewardable
    extend ActiveSupport::Concern

    # rubocop:disable Metrics/BlockLength
    included do
      state_machine use_transactions: true do
        before_transition in_progress: :accepted do |votable, _|
          votable.award_creator!
          votable.award_upvoters!
          votable.punish_downvoters!
        end

        before_transition in_progress: :denied do |votable, _|
          votable.punish_creator!
          votable.punish_upvoters!
          votable.award_downvoters!
        end
      end

      def award_creator!
        creator.boosts.create(reputation: creator_prize, activity: transition_activity)
      end

      def punish_creator!
        creator.boosts.create(reputation: creator_penalty, activity: transition_activity)
      end

      def award_upvoters!
        Boost.transaction do
          User.where(id: upvotes.select(:user_id)).each do |user|
            user.boosts.create(reputation: upvoter_prize, activity: transition_activity)
          end
        end

        # Direct SQL won't work - since the counter cache is not updated!
        #
        # will need to look for other solutions that scale with 1000s of votes
        # maybe add DB triggers for the counter_cache update?
        #
        # ActiveRecord::Base.connection.execute(%{
        #   INSERT INTO boosts (
        #     activity_id,
        #     reputation,
        #     user_id,
        #     created_at,
        #     updated_at
        #   )
        #   SELECT
        #     #{transition_activity.id},
        #     #{upvoter_prize},
        #     votes.user_id,
        #     current_timestamp,
        #     current_timestamp
        #   FROM votes
        #   WHERE votable_id = #{self.id}
        #     AND votable_type = '#{self.class.base_class.name}'
        #     AND accept = TRUE
        # })
      end

      def punish_upvoters!
        Boost.transaction do
          User.where(id: upvotes.select(:user_id)).each do |user|
            user.boosts.create(reputation: upvoter_penalty, activity: transition_activity)
          end
        end
      end

      def award_downvoters!
        Boost.transaction do
          User.where(id: downvotes.select(:user_id)).each do |user|
            user.boosts.create(reputation: downvoter_prize, activity: transition_activity)
          end
        end
      end

      def punish_downvoters!
        Boost.transaction do
          User.where(id: downvotes.select(:user_id)).each do |user|
            user.boosts.create(reputation: downvoter_penalty, activity: transition_activity)
          end
        end
      end

      # created good stuff
      def creator_prize
        @creator_prize ||= ENVProxy.required_integer("#{class_name_env}_CREATOR_PRIZE")
      end

      # created trash
      def creator_penalty
        @creator_penalty ||= ENVProxy.required_integer("#{class_name_env}_CREATOR_PENALTY")
      end

      # upvoted good stuff
      def upvoter_prize
        @upvoter_prize ||= ENVProxy.required_integer("#{class_name_env}_UPVOTER_PRIZE")
      end

      # upvoted trash
      def upvoter_penalty
        @upvoter_penalty ||= ENVProxy.required_integer("#{class_name_env}_UPVOTER_PENALTY")
      end

      # downvoted trash
      def downvoter_prize
        @downvoter_prize ||= ENVProxy.required_integer("#{class_name_env}_DOWNVOTER_PRIZE")
      end

      # downvoted good stuff
      def downvoter_penalty
        @downvoter_penalty ||= ENVProxy.required_integer("#{class_name_env}_DOWNVOTER_PENALTY")
      end

      def class_name_env
        self.class.name.upcase
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
