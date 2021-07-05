Feature: Effects
  Scenario: Evaluate multiple effects
    Given a file named "main.cloe" with:
    """
    (print 123)
    (print 456)
    (print 789)
    """
    When I successfully run `cloe main.cloe`
    Then the stdout should contain "123"
    And the stdout should contain "456"
    And the stdout should contain "789"

  Scenario: Evaluate an expanded effect
    Given a file named "main.cloe" with:
    """
    ..[(print 123) (print 456) (print 789)]
    """
    When I successfully run `cloe main.cloe`
    Then the stdout should contain "123"
    And the stdout should contain "456"
    And the stdout should contain "789"

  Scenario: Purify an effect value
    Given a file named "main.cloe" with:
    """
    (print (pure (print "Hello, world!")))
    """
    When I successfully run `cloe main.cloe`
    Then the stdout should contain exactly:
    """
    Hello, world!
    nil
    """
