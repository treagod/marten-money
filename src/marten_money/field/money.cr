module MartenMoney
  module Field
    class Money < Marten::DB::Field::Base
      getter default

      def initialize(
        @id : ::String,
        @blank = false,
        @null = false,
        @default : ::Money | Nil = nil,
      )
        @unique = false
        @index = false
        @primary_key = false
        @db_column = nil
      end

      def db_column
        # No-op
      end

      def default
        # No-op
      end

      def from_db(value) : Nil
        # No-op
      end

      def from_db_result_set(result_set : ::DB::ResultSet) : Nil
        # No-op
      end

      def perform_validation(record : Marten::Model)
        # No-op
      end

      def to_column : Marten::DB::Management::Column::Base?
        # No-op
      end

      def to_db(value) : ::DB::Any
        # No-op
      end

      # :nodoc:
      macro check_definition(field_id, kwargs)
        {% if kwargs && kwargs[:amount_field_id] && kwargs[:currency_field_id] &&
                kwargs[:amount_field_id] != "" && kwargs[:amount_field_id] == kwargs[:currency_field_id] %}
          {% raise "amount_field_id and currency_field_id cannot be the same" %}
        {% end %}
      end

      # :nodoc:
      macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
        {% if kwargs.is_a?(NilLiteral) %}
          {% amt_field_id = "#{field_id}_amount".id %}
          {% cur_field_id = "#{field_id}_currency".id %}
        {% else %}
          {% amt_field_id = kwargs[:amount_field_id] || "#{field_id}_amount".id %}
          {% cur_field_id = kwargs[:currency_field_id] || "#{field_id}_currency".id %}
        {% end %}

        class ::{{ model_klass }}
          register_field(
            {{ @type }}.new(
              {{ field_id.stringify }},
              {% unless kwargs.is_a?(NilLiteral) %}**{{ kwargs }}{% end %}
            )
          )

          {% if kwargs && kwargs[:default] %}
            {% call = kwargs[:default] %}
            {% unless call.is_a?(Call) &&
                        call.name == "new" &&
                        call.receiver.is_a?(Path) &&
                        call.receiver.stringify == "Money" &&
                        call.args.size == 2 &&
                        call.args[0].is_a?(NumberLiteral) &&
                        call.args[1].is_a?(StringLiteral) %}
              {% raise "default: must be a literal Money.new(integer, \"CUR\")" %}
            {% end %}

            {% amount_lit = call.args[0] %}
            {% currency_lit = call.args[1] %}
          {% end %}

          field(:{{amt_field_id}}, :big_int{% if !kwargs.is_a?(NilLiteral) %},
            {% if kwargs[:blank] %}
              blank: true,
            {% end %}
            {% if kwargs[:null] %}
              null: true,
            {% end %}
            {% if kwargs[:default] %}
              default: {{ amount_lit }},
            {% end %}
          {% end %}
          )
          field(:{{cur_field_id}}, :string, max_size: 3{% if !kwargs.is_a?(NilLiteral) %},
            {% if kwargs[:blank] %}
              blank: true,
            {% end %}
            {% if kwargs[:null] %}
              null: true,
            {% end %}
            {% if kwargs[:default] %}
              default: {{ currency_lit }},
            {% end %}
          {% end %}
          )

          {% if !model_klass.resolve.abstract? %}
            @[Marten::DB::Model::Table::FieldInstanceVariable(
              field_klass: {{ @type }},
              field_kwargs: {{ kwargs }},
              field_type: {{ field_ann[:exposed_type] }},
              model_klass: {{ model_klass }}
            )]
            @{{ field_id }} : ::Money?
            @__cached_{{ field_id }} : ::Money?

            def {{ field_id }} : ::Money?
              @__cached_{{ field_id }} ||= begin
                a = self.{{amt_field_id}}
                c = self.{{cur_field_id}}
                ::Money.new(a.not_nil!, c.not_nil!) unless a.nil? || c.nil?
              end
            end

            def {{ field_id }}! : ::Money
              {{ field_id }}.not_nil!
            end

            def {{ field_id }}=(val : ::Money)
              self.{{amt_field_id}} = val.fractional.to_i64
              self.{{cur_field_id}} = val.currency.code
              @__cached_{{ field_id }}      = val
            end

            def {{ field_id }}=(val : JSON::Serializable)
              self.{{ field_id }} = ::Money.from_json(val.to_json)
            end

            def {{ field_id }}=(val : Nil)
              self.{{amt_field_id}} = nil
              self.{{cur_field_id}} = nil
              @__cached_{{ field_id }}      = nil
            end
          {% end %}
        end
      end
    end
  end
end

Marten::DB::Field.register(:money, MartenMoney::Field::Money)
