module MartenMoney
  module Field
    module Money
      macro included
        _begin_model_setup

        macro inherited
          _begin_model_setup

          macro finished
            _finish_model_setup
          end
        end

        macro finished
          _finish_model_setup
        end
      end

      macro _begin_model_setup
        MARTEN_MONEY_FIELDS = [] of String
      end

      macro _finish_model_setup
        private def initialize_field_values(kwargs)
          named_hash = kwargs.to_h
          {% for field_name in MARTEN_MONEY_FIELDS %}
            money_arg_{{field_name.id}} = named_hash.delete(:{{field_name.id}})
          {% end %}

          super(named_hash)

          {% for field_name in MARTEN_MONEY_FIELDS %}
          self.{{field_name.id}} = money_arg_{{field_name.id}} if money_arg_{{field_name.id}}
          {% end %}
        end
      end

      macro money_field(field_name, *, blank = false, null = false)
        {% MARTEN_MONEY_FIELDS << field_name.id %}

        {% amount_column = "#{field_name.id}_amount".id %}
        {% currency_column = "#{field_name.id}_currency".id %}

        field :{{amount_column}}, :big_int, blank: {{ blank }}, null: {{ null }}
        field :{{currency_column}}, :string, max_size: 3, blank: {{ blank }}, null: {{ null }}

        def {{field_name.id}} : Money{% if null %}?{% end %}
          {% if !null %}
            Money.new(self.{{amount_column}}!, self.{{currency_column}}!)
          {% else %}
            Money.new(self.{{amount_column}}!, self.{{currency_column}}!) if self.{{amount_column}}
          {% end %}
        end

        def {{field_name.id}}=(value : Money)
          self.{{amount_column}} = value.fractional.to_i64
          self.{{currency_column}} = value.currency.code
        end

        def {{field_name.id}}=(value : Int32 | Int64)
          self.{{amount_column}} = value
        end
      end
    end
  end
end
