class ApplicationRecord < ActiveRecord::Base
  # https://www.keypup.io/blog/graphql-the-rails-way-part-1-exposing-your-resources-for-querying
  include GraphqlQueryScopes

  self.abstract_class = true
end
