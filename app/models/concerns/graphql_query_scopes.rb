# tutorial for filtering GraphQL queries: https://www.keypup.io/blog/graphql-the-rails-way-part-1-exposing-your-resources-for-querying

# app/models/concerns/graphql_query_scopes.rb
# frozen_string_literal: true

module GraphqlQueryScopes
  extend ActiveSupport::Concern

  # List of SQL operators supported by the with_api_filters scope
  SQL_OPERATORS = {
    eq: '= ?',
    gt: '> ?',
    gte: '>= ?',
    lt: '< ?',
    lte: '<= ?',
    in: 'IN (?)',
    nin: 'NOT IN (?)'
  }.freeze

  class_methods do
    # If you use Postgres or any database storing date with millesecond precision
    # then you might want to uncomment the body of this method.
    #
    # Millisecond precision makes timestamp equality and less than filters almost 
    # useless.
    #
    # Format field for SQL queries. Truncate dates to second precision.
    # Used to build filtering queries based on attributes coming from the API.
    def loose_precision_field_wrapper(field)
      "#{table_name}.#{field}"

      # if columns_hash[field.to_s].type == :datetime
      #   "date_trunc('second', #{table_name}.#{field})"
      # else
      #   "#{table_name}.#{field}"
      # end
    end
  end

  included do
    # Sort by created_at to have consistent pagination.
    # This is particularly important when using UUID for IDs
    default_scope { order(created_at: :asc, id: :asc) }

    # This scopes aims at being overriden in children models
    # This scope should typically specify eager loaded associations
    # e.g. scope :graphql_scope { includes(:owner, :team) }
    scope :graphql_scope, -> { all }

    # Allow sorting using a 'dot' syntax (e.g. name.asc). 
    # Supports underscore and camelized attributes. 
    # This scope is typically used on the API
    scope :with_sorting, lambda { |sort_by|
      return all if sort_by.blank?

      # Extract attributes
      sort_attr, sort_dir = sort_by.split('.')

      # Format attributes
      sort_attr = sort_attr.underscore
      sort_dir = 'asc' unless %w[asc desc].include?(sort_dir)

      # Order scope or return self if the attribute does not exist
      column_names.include?(sort_attr) ? unscope(:order).order(sort_attr => sort_dir) : all
    }

    # Allow filtering using attribute-level operators coming from the API.
    # E.g.
    # - created_at_gte => created_at greater than or equal to value
    # - id_in => ID in list of values
    #
    # The list of operators is:
    # *_gt => strictly greater than
    # *_gte => greater than or equal
    # *_lt => strictly less than
    # *_lte => less than or equal
    # *_in => value in array
    # *_nin => value not in array
    scope :with_api_filters, lambda { |args_hash|
      # Build a SQL fragment for each argument
      # Array is first build as [['table.field1 > ?', 123], [['table.field2 < ?', 400]]]
      # then transposed into [['table.field1 > ?', 'table.field2 < ?'], [[123, 400]]]
      sql_fragments, values = args_hash.map do |k, v|
        # Capture the field and the operator
        if column_names.include?(k.to_s)
          field = k
          operator = :eq
        else
          field, _, operator = k.to_s.rpartition('_')
        end

        # Sanitize the field and operator
        raise ActiveRecord::StatementInvalid, "invalid operator #{k}" unless column_names.include?(field.to_s) && SQL_OPERATORS[operator.to_sym]

        # Build SQL fragment
        field_fragment = "#{loose_precision_field_wrapper(field)} #{SQL_OPERATORS[operator.to_sym]}"

        # Return fragment and value
        [field_fragment, v]
      end.compact.transpose

      # Combine regular args and SQL fragments to form the final scope
      where(Array(sql_fragments).join(' AND '), *values)
    }
  end
end