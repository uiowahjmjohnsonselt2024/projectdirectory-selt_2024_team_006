Feature: Shop purchases and inventory management

  Background:
    Given a user with 100 shards exists
    And an item with a price of 50 shards exists

  Scenario: User successfully buys an item with enough shards
    Given the user is signed in
    Given I am on the shop page
    When the user buys an item priced at 50 shards
    Then the user's shard balance should be 50
    Then I should see "Successfully bought Magic Sword!"

  Scenario: User cannot buy an item with insufficient shards
    Given an item with a price of 150 shards exists
    And the user is signed in
    Given I am on the shop page
    When the user buys an item priced at 150 shards
    Then the user's shard balance should be 100
    Then I should see "Not enough shards!"

  Scenario: User sells an item they own
    Given the user is signed in
    Given I am on the shop page
    When the user buys an item priced at 50 shards
    When the user sells the item
    Then the user's shard balance should be 88
    Then I should see "Successfully sold Magic Sword for 38 Shards!"

  Scenario: I should not see the default weapon
    Given the user is signed in
    Given I am on the shop page
    Then I should not see "Basic Dagger"
