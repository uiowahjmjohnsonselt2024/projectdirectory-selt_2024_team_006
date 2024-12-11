Feature: Manage Worlds
  As a user of Shards of the Grid
  I want to create and view worlds
  So that I can start a new game or continue an existing one

  Background:
    Given I am signed up and logged in as a user
    And I am on the single player page

  Scenario: Creating a new world with a custom name
    When I click "Create New World"
    And I fill in the world name field with "My Custom World"
    And I press "Create World"
    Then I should see "World created successfully!"
    And I should see "My Custom World" in the list of saved worlds

  Scenario: Creating a new world with a blank name
    When I click "Create New World"
    And I leave "World Name" blank
    And I press "Create World"
    Then I should see "World created successfully!"
    And I should see "New World" in the list of saved worlds

  Scenario: Viewing saved worlds
    Given I have created worlds named "World A" and "World B"
    When I visit the single player page
    Then I should see "World A" in the list of saved worlds
    And I should see "World B" in the list of saved worlds

  Scenario: Trying to view a world that does not belong to the user
    Given there is a world created by another user with the name "Forbidden World"
    When I attempt to visit the "Forbidden World" page
    Then I should see "World not found."
    And I should be on the single player page
