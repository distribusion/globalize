module Globalize
  module ActiveRecord
    class Translation < ::ActiveRecord::Base

      validates :locale, :presence => true
      validate :validate_uniqueness_of_combination_of_locale_and_foreign_key

      class << self
        # Sometimes ActiveRecord queries .table_exists? before the table name
        # has even been set which results in catastrophic failure.
        def table_exists?
          table_name.present? && super
        end

        def with_locales(*locales)
          # Avoid using "IN" with SQL queries when only using one locale.
          locales = locales.flatten.map(&:to_s)
          locales = locales.first if locales.one?
          where :locale => locales
        end
        alias with_locale with_locales

        def translated_locales
          select('DISTINCT locale').order(:locale).map(&:locale)
        end
      end

      def locale
        _locale = read_attribute :locale
        _locale.present? ? _locale.to_sym : _locale
      end

      def locale=(locale)
        write_attribute :locale, locale.to_s
      end

      private

      def foreign_attribute
        self.class.reflections["globalized_model"].options[:foreign_key].to_sym
      end

      def validate_uniqueness_of_combination_of_locale_and_foreign_key
        if (self.class.where(foreign_attribute => send(foreign_attribute), locale: locale) - [self.class.where(id: self.id).first]).count == 1
          errors.add(foreign_attribute)
        end
      end

    end
  end
end

# Setting this will force polymorphic associations to subclassed objects
# to use their table_name rather than the parent object's table name,
# which will allow you to get their models back in a more appropriate
# format.
#
# See http://www.ruby-forum.com/topic/159894 for details.
Globalize::ActiveRecord::Translation.abstract_class = true
