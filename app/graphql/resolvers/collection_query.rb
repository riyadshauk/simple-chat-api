# app/graphql/resolvers/collection_query.rb
# frozen_string_literal: true

# code from tutorial: https://www.keypup.io/blog/graphql-the-rails-way-part-1-exposing-your-resources-for-querying

module Resolvers
  # Parameterized Class used to generate resolvers finding multiple records via
  # filtering attributes
  #
  # Example:
  # Generate resolver for Types::MyClassType which is assumed to use the 'MyClass'
  # ActiveRecord model under the hood:
  # field :my_class, resolver: CollectionQuery.for(Types::MyClassType)
  #
  # Generate resolver for an association where the association name can be inferred from
  # the type class
  # field :posts, resolver: CollectionQuery.for(Types::PostType)
  #
  # Generate resolver for an association where the association cannnot be inferred
  # from the type class passed to the resolver
  # field :published_posts, resolver: CollectionQuery.for(Types::MyClassType, relation: :published_posts)
  #
  class CollectionQuery < GraphQL::Schema::Resolver
    # Class insteance variables that can be inherited by child classes
    class_attribute :base_type, :resolver_opts

    #---------------------------------------
    # Constants
    #---------------------------------------
    # Define the operators accepted for each field type
    FILTERING_OPERATORS = {
      GraphQL::Types::ID => %i[in nin],
      GraphQL::Types::String => %i[in nin],
      GraphQL::Schema::Enum => %i[in nin],
      GraphQL::Types::ISO8601DateTime => %i[gt gte lt lte in nin],
      GraphQL::Types::Float => %i[gt gte lt lte in nin],
      GraphQL::Types::Int => %i[gt gte lt lte in nin]
    }.freeze

    #---------------------------------------
    # Class Methods
    #---------------------------------------
    # Return a child resolver class configured for the specified entity type
    def self.for(entity_type, **args)
      Class.new(self).setup(entity_type, args)
    end

    # Setup method used to configure the class
    def self.setup(entity_type, **args)
      # Configure class
      use_base_type entity_type
      use_resolver_opts args

      # Set resolver type
      type [entity_type], null: false

      # Define each entity field as a filtering argument
      filter_fields.each do |field_name, field_type|
        argument field_name, field_type, required: false
      end

      # Sort field
      argument :sort_by, String, required: false, description: 'Use dot notation to sort by a specific field. E.g. `createdAt.asc` or `createdAt.desc`.'

      # Return class for chaining
      self
    end

    # Set the base entity type
    def self.use_base_type(type_klass = nil)
      self.base_type = type_klass
    end

    # Set the resolver options
    def self.use_resolver_opts(opts = nil)
      self.resolver_opts = HashWithIndifferentAccess.new(opts)
    end

    #
    # Return all base fields that can be used to generate filters
    #
    # @return [Hash] A hash of Field Name => GraphQL Field Type
    #
    def self.queriable_fields
      native_queriable_fields.merge(association_queriable_fields)
    end

    #
    # Return the list of native fields that can be used for filtering
    #
    # @return [Hash] A hash of field name => field type
    #
    def self.native_queriable_fields
      base_type
        .fields
        .select { |k, _v| model_klass.column_names.include?(k.to_s.underscore) }
        .select { |_k, v| v.type.unwrap.kind.input? && !v.type.list? }
        .map { |k, v| [k, v.type.unwrap] }
        .to_h
    end

    #
    # Return the list of belongs_to fields that can be used for filtering
    #
    # @return [Hash] A hash of field name => field type
    #
    def self.association_queriable_fields
      base_type
        .fields
        .values
        .select { |v| v.type.unwrap.kind.object? }
        .map { |v| model_klass.reflect_on_all_associations(:belongs_to).find { |e| e.name.to_s == v.name.to_s } }
        .compact
        .map { |e| [e.foreign_key, GraphQL::Types::ID] }
        .to_h
    end

    # Return the list of fields accepted as filters (including operators)
    def self.filter_fields
      # Used queriable fields as equality filters
      equality_fields = queriable_fields

      # For each queriable field, find the list of operators applicable for the field class
      operator_fields = equality_fields.map do |field_name, field_type|
        # Find applicable operators by looking up the field type ancestors
        operators = FILTERING_OPERATORS.find { |klass, _| field_type <= klass }&.last
        next unless operators

        # Generate all operator fields
        operators.map do |o|
          arg_type = %i[in nin].include?(o) ? [field_type] : field_type
          ["#{field_name.underscore}_#{o}".to_sym, arg_type]
        end
      end.compact.flatten(1).to_h

      # Return equality and operator-based fields
      equality_fields.merge(operator_fields)
    end

    # Return the underlying ActiveRecord model class
    def self.model_klass
      @model_klass ||= (resolver_opts[:model_name] || base_type.to_s.demodulize.gsub(/Type$/, '')).constantize
    end

    # Return the model Pundit Policy class
    def self.pundit_scope_klass
      @pundit_scope_klass ||= "#{model_klass}Policy::Scope".constantize
    end

    #---------------------------------------
    # Instance Methods
    #---------------------------------------
    # Retrieve the current user from the GraphQL context.
    # This current user must be injected in context inside the GraphqlController.
    def current_user
      @current_user ||= context[:current_user]
    end

    # Reject request if the user is not authenticated
    def authorized?(**args)
      super && (!defined?(Pundit) || current_user || raise(Pundit::NotAuthorizedError))
    end

    # Return the name of the association that should be defined on the parent
    # object
    def parent_association_name
      self.class.resolver_opts[:relation] ||
        self.class.model_klass.to_s.underscore.pluralize
    end

    # Return the instantiated resource scope via Pundit
    # If a parent object is defined then it is assumed that the resolver is
    # called within the context of an association
    def pundit_scope
      base_scope = object ? object.send(parent_association_name) : self.class.model_klass

      # Enforce Pundit control if the gem is present
      # This current user must be injected in context inside the GraphqlController.
      if defined?(Pundit)
        self.class.pundit_scope_klass.new(current_user, base_scope.graphql_scope).resolve
      else
        base_scope.graphql_scope
      end
    end

    # Actual resolver method performing the ActiveRecord filtering query
    #
    # The resolver supports filtering via a range of operators:
    # * => field equal to value
    # *_gt => strictly greater than
    # *_gte => greater than or equal
    # *_lt => strictly less than
    # *_lte => less than or equal
    # *_in => value in array
    # *_nin => value not in array
    # > See ApplicationRecord#with_api_filters for the underlying filtering logic
    #
    # The resolver supports sorting via 'dot' syntax:
    # sortBy: 'createdAt.desc'
    # > See ApplicationRecord#with_sorting for the underlying sorting logic
    #
    def resolve(sort_by: nil, **args)
      pundit_scope.with_api_filters(args).with_sorting(sort_by)
    end
  end
end