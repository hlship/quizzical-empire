event = require "events"
_ = require "underscore"

# Helps to organize callbacks.  At this time, it breaks normal
# conventions and makes not attempt to catch errors or fire an 'error'
# event.
class Flow extends event.EventEmitter

  constructor: ->
    @count = 0
    # Array of zero-arg functions that invoke join callbacks
    @joins = []

  invokeJoins: ->
      # The join callbacks may add further callbacks or further join
      # callbacks, but that only affects future completions.
      joins = @joins
      @joins = []
      join.call(null) for join in joins
      @emit 'join', this

  checkForJoin: ->
    @invokeJoins() if --@count == 0

  # Adds a callaback and returns a function that will invoke the
  # callback. Adding a callback increases the count. The count is
  # decreased after the callback is invoked.  Callbacks are invoked
  # with 'this' set to null.  Join callbacks are invoked when the count
  # reaches zero. Callbacks should be added before join callbacks are
  # added. Assumes each callback will be called exactly once, though
  # this is not checked for.
  add: (callback) ->

    # One more callback until we can invoke join callbacks
    @count++

    (args...) =>
      callback.apply null, args...

      @checkForJoin()

  # Adds a join callback, which will be invoked after all previously
  # added callbacks have been invoked. Join callbacks are invoked with
  # 'this' set to null and no arguments. Emits a 'join' event, passing
  # this Flow, after invoking any explicitly added join callbacks.
  # Invokes the callback immediately if there are no outstanding
  # callbacks.
  join: (callback) ->

    @joins.push callback

    @invokeJoins() if @count == 0

  # TODO:
  # sub flows (for executing related tasks in parallel)

module.exports = Flow