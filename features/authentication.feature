Feature: User Authentication
  As a user
  I want to be able to sign up, sign in, and sign out
  So that I can access protected parts of the app

  Scenario: User signs up successfully
    Given I am on the sign up page
    When I fill in "Email" with "newuser@example.com"
    And I fill in "Password" with "password123"
    And I fill in "Password confirmation" with "password123"
    And I press "Sign up"
    Then I should see "Welcome! You have signed up successfully."

  Scenario: User signs in successfully
    Given a user exists with email "test@example.com" and password "password123"
    When I am on the sign in page
    And I fill in "Email" with "test@example.com"
    And I fill in "Password" with "password123"
    And I press "Log in"
    Then I should see "Signed in successfully."

  Scenario: User signs out successfully
    Given a user exists with email "test@example.com" and password "password123"
    And I am signed in as "test@example.com"
    When I click "Sign Out"
    Then I should see "Signed out successfully."
