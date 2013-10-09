require_dependency 'issue'
require_relative '../../app/services/issue_visibility'

module RedmineLimitedVisibility
  module IssuePatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        alias_method_chain :visible?, :limited_visibility
      end
    end

    module InstanceMethods
      def visible_with_limited_visibility?(user = nil)
        visible_without_limited_visibility?(user) && IssueVisibility.new(user, self).authorized?
      end
    end
  end
end

unless Issue.included_modules.include? RedmineLimitedVisibility::IssuePatch
  Issue.send :include, RedmineLimitedVisibility::IssuePatch
end
