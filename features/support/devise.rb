# frozen_string_literal: true

require 'warden'
Warden.test_mode!

World Warden::Test::Helpers
After { Warden.test_reset! }
