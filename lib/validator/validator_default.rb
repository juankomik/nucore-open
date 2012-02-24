#
# This class defines an interface for validating
# payment source strings. It is also the default
# for validating payment sources. As such it does
# very little. In fact, it will consider every payment
# source it validates as valid. Every real nucore instance
# should replace this class with institution-specific
# validation rules. See +ValidatorFactory+ for details
# on how to do that.
class ValidatorDefault

  #
  # Returns the payment source format that is
  # considered valid. Example: '123-456-7890'
  def self.pattern_format
    '++ any characters ++'
  end


  #
  # Returns the regexp that validates +#pattern_format+
  def self.pattern
    /.+/
  end



  #
  # This class will not use anything you pass in.
  def initialize(*args)
  end


  #
  # Validate a payment source. Returns nil and raises
  # no +Exception+ if a payment source is open for new
  # payments. Otherwise a +ValidatorError+ will be raised.
  def account_is_open!
  end


  #
  # [_return_]
  #   the latest expiration date for a payment source
  def latest_expiration
    Time.zone.now + 1.year
  end


  #
  # [_return_]
  #   true if all components of a payment source are known, false otherwise.
  # [_example_]
  #   string '123-456-789' has 3 components
  def components_exist?
    true
  end

end