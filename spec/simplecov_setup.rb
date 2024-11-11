# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

SimpleCov.minimum_coverage 100
puts 'Code coverage will be generated in /coverage'
