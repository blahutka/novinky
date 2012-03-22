require 'rubygems'
require 'active_support/all'
require "active_support/inflector"

$KCODE = 'UTF8'

module Rails
  class Initializer
    def initialize_encoding
      $KCODE = 'UTF8' if RUBY_VERSION < '1.9'
    end
  end
end
