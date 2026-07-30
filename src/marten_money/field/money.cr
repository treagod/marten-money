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

          if @store_currency && @amount_field_id == @currency_field_id
            raise ArgumentError.new(
              "Money field '#{@id}' resolves amount_field_id and currency_field_id to the same " \
              "identifier '#{@amount_field_id}'"
            )
          end

          if @amount_field_id == @id
            raise ArgumentError.new(
              "Money field '#{@id}' resolves its amount_field_id to the money field's own identifier '#{@id}'"
            )
          end

          if @store_currency && @currency_field_id == @id
            raise ArgumentError.new(
              "Money field '#{@id}' resolves its currency_field_id to the money field's own identifier '#{@id}'"
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

        def from_db(value) : ::Money?
          # No-op
        end

        def from_db_result_set(result_set : ::DB::ResultSet) : ::Money?
          # No-op
        end

        # Converts *value* into an `Int64` amount of minor units for the generated amount field.
        #
        # The exact amount is derived from `Money#amount` because `Money#fractional` silently drops
        # sub-minor-unit precision when `Money.infinite_precision?` is enabled. Values that cannot be
        # represented exactly as an `Int64` raise an `ArgumentError`.
        def self.fractional_to_i64(value : ::Money, field_id : ::String) : Int64
          fractional = value.amount * value.currency.subunit_to_unit

          unless fractional == fractional.trunc
            raise ArgumentError.new(
              "Money field '#{field_id}' cannot store #{value.amount} #{value.currency.code} exactly: " \
              "#{fractional} is not a whole number of minor units"
            )
          end

          unless fractional >= Int64::MIN && fractional <= Int64::MAX
            raise ArgumentError.new(
              "Money field '#{field_id}' cannot store #{value.amount} #{value.currency.code} exactly: " \
              "#{fractional.to_big_i} minor units do not fit into the Int64 amount column"
            )
          end

          fractional.to_big_i.to_i64
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

        {% model_type = model_klass.resolve %}
        {% field_id_str = field_id.stringify %}
        {% amt_field_id_str = amt_field_id.stringify %}
        {% cur_field_id_str = cur_field_id.stringify %}

        {% if store_currency && amt_field_id_str == cur_field_id_str %}
          {% raise "Money field '#{field_id}' resolves amount_field_id and currency_field_id to the same " +
                   "identifier '#{amt_field_id}'" %}
        {% end %}

        {% if amt_field_id_str == field_id_str %}
          {% raise "Money field '#{field_id}' resolves its amount_field_id to the money field's own " +
                   "identifier '#{field_id}'" %}
        {% end %}

        {% if store_currency && cur_field_id_str == field_id_str %}
          {% raise "Money field '#{field_id}' resolves its currency_field_id to the money field's own " +
                   "identifier '#{field_id}'" %}
        {% end %}

        {% generated_ids = [{amt_field_id_str, "amount"}] %}
        {% if store_currency %}
          {% generated_ids << {cur_field_id_str, "currency"} %}
        {% end %}

        # An ancestor declaring this exact money field (same id, same resolved identifiers) means Marten is
        # re-contributing an inherited field: its generated identifiers legitimately exist in the inherited
        # FIELDS_ entries and were already validated when the ancestor itself was compiled.
        {% inherited_money_field = false %}
        {% for ancestor_model in model_type.ancestors %}
          {% if !inherited_money_field && ancestor_model.has_constant?("FIELDS_") %}
            {% ancestor_entry = ancestor_model.constant("FIELDS_")[field_id_str] %}
            {% if ancestor_entry && ancestor_entry[:type] == "money" %}
              {% ancestor_kwargs = ancestor_entry[:kwargs] %}
              {% ancestor_amt = (ancestor_kwargs[:amount_field_id] || "#{field_id}_amount").id %}
              {% ancestor_cur = (ancestor_kwargs[:currency_field_id] || "#{field_id}_currency").id %}
              {% ancestor_stores_currency = !ancestor_kwargs[:fixed_currency] %}
              {% if ancestor_amt.stringify == amt_field_id_str &&
                      ancestor_stores_currency == store_currency &&
                      (!store_currency || ancestor_cur.stringify == cur_field_id_str) %}
                {% inherited_money_field = true %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}

        {% unless inherited_money_field %}
          {% for ancestor_model in model_type.ancestors %}
            {% if ancestor_model.has_constant?("FIELDS_") %}
              {% for generated_id in generated_ids %}
                {% if ancestor_model.constant("FIELDS_")[generated_id[0]] %}
                  {% raise "Money field '#{field_id}' would define its #{generated_id[1].id} field " +
                           "'#{generated_id[0].id}', which is already defined by ancestor model '#{ancestor_model}'" %}
                {% end %}
              {% end %}
            {% end %}
          {% end %}

          {% if model_type.has_constant?("FIELDS_") %}
            {% for generated_id in generated_ids %}
              {% if model_type.constant("FIELDS_")[generated_id[0]] %}
                {% raise "Money field '#{field_id}' would define its #{generated_id[1].id} field " +
                         "'#{generated_id[0].id}', which is already defined by model '#{model_type}'" %}
              {% end %}
            {% end %}
          {% end %}
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
                        call.args[0].kind != :f32 &&
                        call.args[0].kind != :f64 &&
                        call.args[1].is_a?(StringLiteral) %}
              {% raise "Money field '#{field_id}' default: must be a literal Money.new call with an integer " +
                       "amount and a string currency, e.g. default: Money.new(10_00, \"EUR\")" %}
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

              self.{{ amt_field_id }} = {{ @type }}.fractional_to_i64(val, {{ field_id.stringify }})
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

Marten::DB::Field.register("money", MartenMoney::DB::Field::Money)
