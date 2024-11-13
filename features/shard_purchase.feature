Feature: Shard Purchase

  Background:
    Given I am signed in as a user

  Scenario: Successfully purchase shards
    Given I am on the shard purchase page
    When I fill in "amount-input" with "10"
    And I fill in "Credit Card Number" with "1234567890123452"
    And I select "USD" from "currency-select"
    Then I press "Purchase Shards"
    Then I should see "Successfully purchased 10 shards!"
    And my shard balance should be "10"

  Scenario: Successfully purchase shards with currency conversion
    Given I am on the shard purchase page
    Given I am purchasing shards with GBP
    When I fill in "amount-input" with "10"
    And I fill in "Credit Card Number" with "1234567890123452"
    And I select "GBP" from "currency-select"
    Then I press "Purchase Shards"
    Then I should see "Successfully purchased 14 shards!"
    And my shard balance should be "14"


  Scenario: Purchase fails with invalid card number
    Given I am on the shard purchase page
    When I fill in "amount-input" with "10"
    And I fill in "Credit Card Number" with "12345678901234"
    And I select "USD" from "currency-select"
    Then I press "Purchase Shards"
    Then I should see "Card number must be 16 digits long"
    And my shard balance should be "0"

  Scenario: Purchase fails with invalid shard amount (<= 0)
    Given I am on the shard purchase page
    When I fill in "amount-input" with "-1"
    And I fill in "Credit Card Number" with "1234567890123452"
    And I select "USD" from "currency-select"
    Then I press "Purchase Shards"
    Then I should see "Amount must be greater than 0"
    And my shard balance should be "0"
