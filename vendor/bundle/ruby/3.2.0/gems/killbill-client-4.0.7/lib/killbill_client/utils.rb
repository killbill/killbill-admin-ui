module KillBillClient
  module Utils
    ACRONYMS = %w(CBA).freeze

    def camelize(underscored_word, first_letter = :upper)
      camelized = underscored_word.to_s.split('_').map do |word|
        if acronym?(word)
          word.upcase
        else
          word[0, 1].upcase + word[1..-1]
        end
      end.join
      camelized = camelized[0, 1].downcase + camelized[1..-1] if first_letter == :lower
      camelized
    end

    def demodulize(class_name_in_module)
      class_name_in_module.to_s.sub(/^.*::/, '')
    end

    def underscore(camel_cased_word)
      word = camel_cased_word.to_s.dup
      word.gsub!(/::/, '/')
      word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      word.tr! '-', '_'
      word.downcase!
      word
    end

    def acronym?(word)
      ACRONYMS.include?(word.to_s.upcase)
    end

    extend self
  end
end
