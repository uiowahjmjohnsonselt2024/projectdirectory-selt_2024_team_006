Feature: User features
  As a user
  I want to view achievements and claim rewards
  So that I can track my progress and receive rewards.

  Scenario: Viewing achievements
    Given I am logged in as a user
    And I have some achievements and progress
    When I visit the achievements page
    Then I should see all achievements
    And I should see my progress for each achievement

  Scenario: Claiming a completed achievement
    Given I am logged in as a user
    And I have completed an achievement that is not claimed
    When I claim the achievement
    Then my shards balance should increase by the reward amount
    And the achievement should be marked as claimed
