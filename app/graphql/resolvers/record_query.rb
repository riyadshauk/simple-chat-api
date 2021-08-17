# app/graphql/resolvers/record_query.rb
# frozen_string_literal: true

# from tutorial: https://www.keypup.io/blog/graphql-the-rails-way-part-1-exposing-your-resources-for-querying

module Resolvers
  # Parameterized Class used to generate resolvers finding a single record
  # using one of its ID keys
  #
  # Example:
  # Generate resolver for Types::MyClassType which is assumed to use the 'MyClass'
  # ActiveRecord model under the hood
  # > RecordQuery.for(Types::MyClassType)
  class RecordQuery < GraphQL::Schema::Resolver
    # Class insteance variables that can be inherited by child classes
    class_attribute :base_type, :resolver_opts

    #---------------------------------------
    # Class Methods
    #---------------------------------------
    # Return a child resolver class configured for the specified entity type
    def self.for(entity_type, **args)
      Class.new(self).setup(entity_type, args)
    end

    # Setup method used to configure the class
    def self.setup(entity_type, **args)
      # Set base type
      use_base_type entity_type
      use_resolver_opts args

      # Set resolver type
      type [entity_type], null: false

      # Define argument for each primary key
      id_fields.each do |f|
        argument f.name, GraphQL::Types::ID, required: false
      end

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

    # Return the list of ID fields
    def self.id_fields
      base_type.fields.values.select { |f| f.type.unwrap == GraphQL::Types::ID }
    end

    # Return the underlying ActiveRecord model class
    def self.entity_klass
      @entity_klass ||= base_type.to_s.demodulize.gsub(/Type$/, '').constantize
    end

    # Return the model Pundit Policy class
    def self.pundit_scope_klass
      @pundit_scope_klass ||= "#{entity_klass}Policy::Scope".constantize
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
        self.class.entity_klass.to_s.underscore.pluralize
    end

    # Return the instantiated resource scope via Pundit
    # If a parent object is defined then it is assumed that the resolver is
    # called within the context of an association
    def pundit_scope
      base_scope = object ? object.send(parent_association_name) : self.class.entity_klass

      # Enforce Pundit control if the gem is present
      # This current user must be injected in context inside the GraphqlController.
      if defined?(Pundit)
        self.class.pundit_scope_klass.new(current_user, base_scope.graphql_scope).resolve
      else
        base_scope.graphql_scope
      end
    end

    # Actual resolver method performing the ActiveRecord find query
    def resolve(**args)
      # Avoid finding by nil value
      return nil if (args_hash = args.compact).blank?

      pundit_scope.find_by(args_hash)
    end
  end
end