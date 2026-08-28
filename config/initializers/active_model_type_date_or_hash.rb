module ActiveModel
  module Type
    class DateOrHash < ActiveModel::Type::Value
    private

      def cast_value(date_params)
        ::Date.new(date_params[1], date_params[2], date_params[3])
      rescue ArgumentError, TypeError, NoMethodError
        date_params
      end
    end

    register(:date_or_hash, DateOrHash)
  end
end
