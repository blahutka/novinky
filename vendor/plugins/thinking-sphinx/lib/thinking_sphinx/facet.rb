module ThinkingSphinx
  class Facet
    attr_reader :property
    
    def initialize(property)
      @property = property
      
      if property.columns.length != 1
        raise "Can't translate Facets on multiple-column field or attribute"
      end
    end

    def self.name_for(facet)
      case facet
      when Facet
        facet.name
      when String, Symbol
        facet.to_s.gsub(/(_facet|_crc)$/,'').to_sym
      end
    end
    
    def self.attribute_name_for(name)
      name.to_s == 'class' ? 'class_crc' : "#{name}_facet"
    end
    
    def self.attribute_name_from_value(name, value)
      case value
      when String
        attribute_name_for(name)
      when Array
        if value.all? { |val| val.is_a?(Integer) }
          name
        else
          attribute_name_for(name)
        end
      else
        name
      end
    end
    
    def self.translate?(property)
      return true if property.is_a?(Field)
      
      case property.type
      when :string
        true
      when :integer, :boolean, :datetime, :float
        false
      when :multi
        !property.all_ints?
      end
    end
    
    def name
      property.unique_name
    end
    
    def attribute_name
      if translate?
        Facet.attribute_name_for(@property.unique_name)
      else
        @property.unique_name.to_s
      end
    end
    
    def translate?
      Facet.translate?(@property)
    end
    
    def type
      @property.is_a?(Field) ? :string : @property.type
    end
    
    def value(object, attribute_value)
      return translate(object, attribute_value) if translate?
      
      case @property.type
      when :datetime
        Time.at(attribute_value)
      when :boolean
        attribute_value > 0
      else
        attribute_value
      end
    end
    
    def to_s
      name
    end
    
    private
    
    def translate(object, attribute_value)
      column.__stack.each { |method|
        return nil unless object = object.send(method)
      }
      if object.is_a?(Array)
        object.collect { |item| item.send(column.__name) }.detect { |item|
          item.to_crc32 == attribute_value
        }
      else
        object.send(column.__name)
      end
    end
    
    def column
      @property.columns.first
    end
  end
end
