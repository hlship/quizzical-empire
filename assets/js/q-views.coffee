{View} = Backbone

$ = window.jQuery

readTemplate = (scriptId) -> $("##{scriptId}").html()

fromMustacheTemplate = (scriptId, attributes) ->
  Mustache.render readTemplate(scriptId), attributes

FormView = View.extend

  # Links a model attribute to a field.
  # name - attribute name
  # selector - used to select the container of the field, the container must
  # contain an <input> element
  # defaults to ".x-#{name}"
  linkField: (name, selector = ".x-#{name}") ->
    $container = @$(selector)
    $field = $container.find "input"

    $field.val @model.get(name)

    $field.on "change", (event) =>
      newValue = event.target.value
      @model.set name, newValue

  linkElement: (name, selector = ".x-#{name}", defaultText) ->
    element = @$(selector)
    update = =>
      element.html (@model.escape name) or defaultText

    # Update now, and on any future change
    update()
    @model.on "change:#{name}", update

# Raises a modal confirmation dialog. Details are provided in additional options
# passed to the constructor:
# options.title -- Title for the modal header
# options.body -- Markup for the body of the dialog
# options.label -- Label for the primary button, default: "Confirm"
# options.buttonClass -- Additional CSS class for the
# primary button, default: "btn-primary"
#
# Triggers a "confirmed" event if the user clicks the confirm button. No event
# is triggered if the user dismisses the dialog or clicks the close button.
ConfirmDialog = View.extend

  initialize: ->
    @$el.html fromMustacheTemplate "ConfirmDialog",
      title: @options.title
      body: @options.body
      label: @options.label or "Confirm"

    @$(".x-confirm").addClass @options.buttonClass or "btn-primary"

    $("body").append(@$el)

    @$el.addClass "fade in"

    # After the modal dialog is hidden, remove it from the DOM
    @$el.modal().on "hidden", =>
      @remove()

   dismissDialog: ->
    @$el.modal "hide"

   doConfirm: ->
     @trigger "confirm"

   events:
    "click .x-confirm": "doConfirm"
    "click .btn": "dismissDialog"

_.extend Quizzical, {fromMustacheTemplate, readTemplate,
  ConfirmDialog, FormView }
