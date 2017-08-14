# https://github.com/jruby/activerecord-jdbc-adapter/issues/780
# https://github.com/rails/rails/commit/ae39b1a03d0a859be9d5342592c8936f89fcbacf

require 'arjdbc'
require 'arjdbc/mysql/adapter.rb'
require 'arjdbc/mysql/schema_creation.rb'

module ArJdbc
  module MySQL

    if defined? ::ActiveRecord::ConnectionAdapters::AbstractAdapter::SchemaCreation
      class SchemaCreation < ::ActiveRecord::ConnectionAdapters::AbstractAdapter::SchemaCreation

        def visit_ChangeColumnDefinition(o)
          column = o.column
          options = o.options
          sql_type = type_to_sql(o.type, options)
          change_column_sql = "CHANGE #{quote_column_name(column.name)} #{quote_column_name(options[:name])} #{sql_type}"
          add_column_options!(change_column_sql, options.merge(:column => column))
          add_column_position!(change_column_sql, options)
        end

        def column_options(o)
          super
        end
    end

    # @override
    def add_column(table_name, column_name, type, options = {})
      add_column_sql = "ALTER TABLE #{quote_table_name(table_name)} ADD #{quote_column_name(column_name)} #{type_to_sql(type, options)}"
      add_column_options!(add_column_sql, options)
      add_column_position!(add_column_sql, options)
      execute(add_column_sql)
    end unless const_defined? :SchemaCreation

    # @override
    def change_column(table_name, column_name, type, options = {})
      column = column_for(table_name, column_name)

      unless options_include_default?(options)
        # NOTE: no defaults for BLOB/TEXT columns with MySQL
        options[:default] = column.default if type != :text && type != :binary
      end

      unless options.has_key?(:null)
        options[:null] = column.null
      end

      change_column_sql = "ALTER TABLE #{quote_table_name(table_name)} CHANGE #{quote_column_name(column_name)} #{quote_column_name(column_name)} #{type_to_sql(type, options)}"
      add_column_options!(change_column_sql, options)
      add_column_position!(change_column_sql, options)
      execute(change_column_sql)
    end

    # Maps logical Rails types to MySQL-specific data types.
    def type_to_sql(type, limit: nil, precision: nil, scale: nil, **)
      case type.to_s
        when 'binary'
          case limit
            when 0..0xfff;           "varbinary(#{limit})"
            when nil;                "blob"
            when 0x1000..0xffffffff; "blob(#{limit})"
            else raise(ActiveRecordError, "No binary type has character length #{limit}")
          end
        when 'integer'
          case limit
            when 1; 'tinyint'
            when 2; 'smallint'
            when 3; 'mediumint'
            when nil, 4, 11; 'int(11)'  # compatibility with MySQL default
            when 5..8; 'bigint'
            else raise(ActiveRecordError, "No integer type has byte size #{limit}")
          end
        when 'text'
          case limit
            when 0..0xff;               'tinytext'
            when nil, 0x100..0xffff;    'text'
            when 0x10000..0xffffff;     'mediumtext'
            when 0x1000000..0xffffffff; 'longtext'
            else raise(ActiveRecordError, "No text type has character length #{limit}")
          end
        when 'datetime'
          return super unless precision

          case precision
            when 0..6; "datetime(#{precision})"
            else raise(ActiveRecordError, "No datetime type has precision of #{precision}. The allowed range of precision is from 0 to 6.")
          end
        else
          super
        end
      end
    end

    def prepare_column_options(column)
      spec = super
      spec.delete(:limit) if column.type == :boolean
      spec
    end

    def translate_exception(exception, message)
      return super unless exception.respond_to?(:errno)

      case exception.errno
        when 1062
          ::ActiveRecord::RecordNotUnique.new(message)
        when 1452
          ::ActiveRecord::InvalidForeignKey.new(message)
        else
          super
      end
    end
  end
end

require 'active_record/connection_adapters/postgresql/schema_definitions'
class ActiveRecord::ConnectionAdapters::PostgreSQL::ColumnDefinition < ActiveRecord::ConnectionAdapters::ColumnDefinition
  attr_accessor :array
end
