module MartenMoney
  module DB
    module Field
      class Money < Marten::DB::Field::Base
        # Returns the configured fixed currency, if any.
        getter fixed_currency : ::Money::Currency?

        def initialize(
          @id : ::String,
          @blank = false,
          @null = false,
          @default : ::Money? = nil,
          amount_field_id : ::String | ::Symbol? = nil,
          currency_field_id : ::String | ::Symbol? = nil,
          fixed_currency : ::String | ::Symbol | Nil = nil,
          store_currency : Bool? = nil,
        )
          @amount_field_id = (amount_field_id || "#{@id}_amount").to_s
          @currency_field_id = (currency_field_id || "#{@id}_currency").to_s
          @fixed_currency = resolve_fixed_currency(fixed_currency)
          @store_currency = @fixed_currency.nil?
          @unique = false
          @index = false
          @primary_key = false
          @db_column = nil

          if store_currency == false && @fixed_currency.nil?
            raise ArgumentError.new(
              "store_currency: false is deprecated; replace it with fixed_currency: \"EUR\""
            )
          end

          if store_currency && @fixed_currency
            raise ArgumentError.new("store_currency: true cannot be used with fixed_currency")
          end

          if currency_field_id && @fixed_currency
            raise ArgumentError.new(
              "currency_field_id cannot be used with fixed_currency because no currency column is generated"
            )
          end

          validate_default_currency
        end

        def db_column
          # No-op
        end

        # Returns `nil` to keep the virtual field out of Marten's default value initialization.
        #
        # The generated amount and currency fields own the persisted defaults. The configured
        # default remains available as metadata through `#money_default`.
        def default
          # No-op
        end

        def from_db(value) : Nil
          # No-op
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : Nil
          # No-op
        end

        # Returns the configured default `Money` value, if any.
        def money_default : ::Money?
          @default
        end

        def perform_validation(record : Marten::Model)
          return unless @store_currency

          amount = record.get_field_value(@amount_field_id)
          currency = record.get_field_value(@currency_field_id)

          return if amount.nil? && currency.nil?

          if amount.nil? || currency.nil?
            record.errors.add(id, "amount and currency must either both be set or both be nil")
          end

          return unless currency
          return if ::Money::Currency.find?(currency.to_s)

          record.errors.add(@currency_field_id, "is not a valid currency")
        end

        def to_column : Marten::DB::Management::Column::Base?
          # No-op
        end

        def to_db(value) : ::DB::Any
          # No-op
        end

        private def resolve_fixed_currency(currency : ::String | ::Symbol | Nil) : ::Money::Currency?
          return if currency.nil?

          ::Money::Currency.find?(currency) || raise ArgumentError.new(
            "fixed_currency #{currency.inspect} is not a known Money currency for field '#{@id}'"
          )
        end

        private def validate_default_currency
          return unless @default && @fixed_currency
          return if @default.not_nil!.currency == @fixed_currency

          raise ArgumentError.new(
            "default currency #{@default.not_nil!.currency.code} must match fixed_currency " \
            "#{@fixed_currency.not_nil!.code} for field '#{@id}'"
          )
        end

        # :nodoc:
        macro check_definition(field_id, kwargs)
        {% if kwargs && kwargs[:amount_field_id] && kwargs[:currency_field_id] &&
                kwargs[:amount_field_id] == kwargs[:currency_field_id] %}
          {% raise "amount_field_id and currency_field_id cannot be the same" %}
        {% end %}

        {% if kwargs && kwargs[:fixed_currency] &&
                !kwargs[:fixed_currency].is_a?(StringLiteral) &&
                !kwargs[:fixed_currency].is_a?(SymbolLiteral) %}
          {% raise "fixed_currency must be a string or symbol literal" %}
        {% end %}

        {% if kwargs && kwargs[:fixed_currency] && kwargs[:currency_field_id] %}
          {% raise "currency_field_id cannot be used with fixed_currency because no currency column is generated" %}
        {% end %}

        {% if kwargs && kwargs[:fixed_currency] && kwargs[:store_currency] == true %}
          {% raise "store_currency: true cannot be used with fixed_currency" %}
        {% end %}

        {% if kwargs && kwargs[:store_currency] == false %}
          {% unless kwargs[:fixed_currency] %}
            {% raise "store_currency: false is deprecated; replace it with fixed_currency: \"EUR\"" %}
          {% end %}

          {% warning "store_currency: false is deprecated; remove it and keep fixed_currency" %}
        {% end %}
      end

        # :nodoc:
        macro contribute_to_model(model_klass, field_id, field_ann, kwargs)
        {% fixed_currency = kwargs && kwargs[:fixed_currency] %}
        {% store_currency = !fixed_currency %}

        {% if kwargs.is_a?(NilLiteral) %}
          {% amt_field_id = "#{field_id}_amount".id %}
          {% cur_field_id = "#{field_id}_currency".id %}
        {% else %}
          {% amt_field = kwargs[:amount_field_id] || "#{field_id}_amount" %}
          {% cur_field = kwargs[:currency_field_id] || "#{field_id}_currency" %}
          {% amt_field_id = amt_field.id %}
          {% cur_field_id = cur_field.id %}
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

          field(:{{ amt_field_id }}, :big_int{% if !kwargs.is_a?(NilLiteral) %},
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

          {% if store_currency %}
            field(:{{ cur_field_id }}, :string, max_size: 3{% if !kwargs.is_a?(NilLiteral) %},
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
          {% end %}

          {% if !model_klass.resolve.abstract? %}
            @[Marten::DB::Model::Table::FieldInstanceVariable(
              field_klass: {{ @type }},
              field_kwargs: {{ kwargs }},
              field_type: {{ field_ann[:exposed_type] }},
              model_klass: {{ model_klass }},
              accessor: {{ field_id }},
            )]
            @{{ field_id }} : ::Money?

            def {{ field_id }} : ::Money?
              a = self.{{ amt_field_id }}
              {% if store_currency %}
                c = self.{{ cur_field_id }}
              {% end %}
              return nil if a.nil?{% if store_currency %} || c.nil?{% end %}

              ::Money.new(
                a.not_nil!,
                {% if store_currency %}
                  c.not_nil!,
                {% else %}
                  _{{ field_id }}_fixed_currency,
                {% end %}
              )
            end

            def {{ field_id }}! : ::Money
              {{ field_id }}.not_nil!
            end

            def {{ field_id }}=(val : ::Money)
              {% unless store_currency %}
              fixed_currency = _{{ field_id }}_fixed_currency
              unless val.currency == fixed_currency
                raise ArgumentError.new(
                  "Money field '{{ field_id }}' requires currency #{fixed_currency.code}, got #{val.currency.code}"
                )
              end
              {% end %}

              self.{{ amt_field_id }} = val.fractional.to_i64
              {% if store_currency %}
              self.{{ cur_field_id }} = val.currency.code
              {% end %}
            end

            def {{ field_id }}=(val : JSON::Serializable)
              self.{{ field_id }} = ::Money.from_json(val.to_json)
            end

            def {{ field_id }}=(val : Nil)
              self.{{ amt_field_id }} = nil
              {% if store_currency %}
              self.{{ cur_field_id }} = nil
              {% end %}
            end

            {% unless store_currency %}
            private def _{{ field_id }}_fixed_currency : ::Money::Currency
              self.class
                .get_field({{ field_id.stringify }})
                .as(MartenMoney::DB::Field::Money)
                .fixed_currency
                .not_nil!
            end
            {% end %}
          {% end %}
        end
      end
      end
    end
  end
end

Marten::DB::Field.register(:money, MartenMoney::DB::Field::Money)
