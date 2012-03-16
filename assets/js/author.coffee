[Model, Collection, View] = [Backbone.Model, Backbone.Collection, Backbone.View]

$ = window.jQuery

displayFirstTab = ->
  $("#top-level-tabs a:first").tab "show"

readTemplate = (scriptId) ->
  $("##{scriptId}").html()

fromMustacheTemplate = (scriptId, attributes) ->
  Mustache.render readTemplate(scriptId), attributes

isBlank = (str) ->
  _.isNull(str) or
  _.isUndefined(str) or
  str.trim() is ""

Quiz = Model.extend
  idAttribute: "_id"
  urlRoot: "/api/quiz"
  validate:
    title:
      required: true

Round = Model.extend()

FormView = View.extend

  # Links a model attribute to a field.
  # name - attribute name
  # className - used to select the container of the field
  # errorMessages -- used to translate validation names (such as
  # "required") to a user-presentable message.
  linkField: (name, className = ".x-#{name}", errorMessages) ->
    $container = @$(className)
    $field = $container.find "input"
    $help = $container.find ".help-inline"

    initialHelpText = $help.html()

    @model.on "error:#{name}", (model, errors) ->
      $container.addClass "error"

      # One error is usually enough. Find the first that has a
      # registrered message.
      message = _.chain(errors[name])
        .map((err) -> errorMessages[err])
        .reject(_.isNull)
        .first()
        .value() || "Invalid input"

      $help.html message

    @model.on "change:#{name}", (model, value) ->
      # We don't update the field itself, because currently changes
      # are always directed from form input out of the field
      $container.removeClass "error"
      $help.html initialHelpText

    $field.val @model.get(name)

    $field.on "change", (event) =>
      # Trigger event, possibly firing error events
      newValue = event.target.value
      valid = @model.set name, newValue
      # Force the issue, to get the model into an invalid state
      if not valid
        @model.set name, newValue, silent:true
        @model.trigger "invalidated", this

QuizList = Collection.extend
  model: Quiz
  url: "/api/quizzes"

ConfirmDeleteDialog = View.extend

  initialize: ->
    @render()

  render: ->
    @$el.html fromMustacheTemplate "delete-quiz-modal",
      title: @model.escape "title"

    $("body").append(@$el)

    @$el.addClass "fade in"

    # After the modal dialog is hidden, remove it from the DOM
    @$el.modal().on "hidden", =>
      @remove()

   dismissDialog: ->
    @$el.modal "hide"

   doConfirm: ->
     @trigger "confirm", @model

   events:
    "click .x-confirm": "doConfirm"
    "click .btn": "dismissDialog"

QuizTableRowView = View.extend
  tagName: "tr"

  initialize: ->
    @model.on "change", @render, this
    @model.on "destroy", @remove, this

    @template = readTemplate "quiz-table-row-template"

  events:
    "click .x-delete": "deleteDialog"
    "click .x-edit": "editQuiz"

  render: ->

    @$el.html Mustache.render @template,
      title: @model.escape "title" || "<em>No Title</em>"
      location: @model.escape "location"
      created: @model.get "created"

    this

  deleteDialog: ->

    new ConfirmDeleteDialog(model: @model).on "confirm", => @model.destroy()

  editQuiz: ->

    new QuizEditorView
      model: @model
      collection: @collection

# Owns the table that displays the current list of Quizzes, including
# the buttons used to create a new quiz, etc.
QuizTableView = View.extend

  initialize: ->

    @quizzes = new QuizList

    @$el.html $("#quiz-table-template").html()

    # Hide the alert and the table initially, while the content is
    # being fetched via Ajax
    @$(".alert, table").hide()

    @quizzes.on "reset", @addAll, this
    @quizzes.on "add", @addOne, this
    @quizzes.on "destroy", @render, this

    @quizzes.fetch()

    @$(".x-create-test-data").popover
      title: "For Testing"
      content: "Creates many Quizzes with random text, for testing purposes.
                This will be removed in the final application."

  addOne: (quiz, collection, options) ->
    view = new QuizTableRowView
      model:quiz
      collection: @quizzes

    # Special case for inserting at index 0, which happens when a new quiz
    # is added in the UI.
    fname = if options? and options.index is 0 then "prepend" else "append"

    @$("tbody")[fname] view.render().el

  addAll: (quizzes) ->
    @$("tbody").empty()

    quizzes.each (quiz) => @addOne quiz
    @render()

  render: ->
    if @quizzes.length is 0
      @$(".alert").show()
      @$("table").hide()
    else
      @$(".alert").hide()
      @$("table").show()
    this

  createTestData: ->
    b = @$(".x-create-test-data")
    b.button('loading').popover('hide')

    $.ajax "/api/create-test-data",
      context: this
      success: (data, status) ->
        b.button('reset')
        @quizzes.fetch()


  createNewQuiz: ->
    new QuizEditorView
      model: new Quiz,
      collection: @quizzes

  events:
    "click .x-create-test-data": "createTestData"
    "click .x-create-new": "createNewQuiz"

# QuizEditorView creates and manages a top level tab for a Quiz.
# Creates a clone of the model which is editted. The original model is
# updated at the end.  TODO: Split this up into one View for handling
# the tabs and the save/cancel button, and additional views for
# everything else.
QuizEditorView = FormView.extend

  className: "tab-pane"

  # Create the top level tab and select it
  initialize: ->

    @originalModel = @model
    @model = @model.clone()

    tabId = _.uniqueId "quiztab_"

    $("#top-level-tabs > ul").append(
      "<li><a href='##{tabId}' data-toggle='tab'>#{@quizName()}</a></li>")

    # Set the id attribute, read the template containing the form,
    # and move it into place.
    @$el.attr("id", tabId).html(
      readTemplate "quiz-edit-form").appendTo("#top-level-tabs > .tab-content")

    @$(".x-cancel").tooltip()

    @viewTab = $("#top-level-tabs .nav-tabs a:[href='##{tabId}']")

    @viewTab.tab "show"

    $("#top-level-tabs .nav-tabs a:last").tab "show"

    @updateSaveButton()

    # More boilerplate.  Kind of wish there was a special
    # Backbone event for unvalidated changes.
    @model.on "change:title", @updateTabTitle, this
    @model.on "change", @updateSaveButton, this
    @model.on "invalidated", @disableSaveButton, this

    # Move the cursor into the title field
    @$(".x-title input").select()

    new QuizFieldsEditorView
      model: @model
      el: @$(".x-quiz-fields")

    # Create a nested view that's responsible for editting, adding,
    # and deleting Rounds
    new QuizRoundsEditorView
      model: @model
      el: @$(".x-rounds")

  remove: ->
    displayFirstTab()

    # Sometimes the tooltip stays after the rest of the UI is discarded,
    # so make sure it is hidden.
    @$(".x-cancel").tooltip "hide"

    @$el.remove()

    # And the LI containing the tab's A
    @viewTab.parent().remove()

    # Don't have to worry about model events, since
    # because we cloned the original model

  updateTabTitle: ->
    @viewTab.html @quizName()

  # Disables the save button unless model is valid
  updateSaveButton: ->
    # TODO: May need to make this smarter, event based,
    # to deal with nested models that may also be invalid.
    @$(".x-save").attr "disabled", not @model.isValid()

  disableSaveButton: ->
    @$(".x-save").attr "disabled", true

  # Handles the case, for new models, that the title may be blank.
  quizName: ->
    @model.escape("title") || "<em>New Quiz</em>"

  doCancel: ->
    # TODO: A modal warning

    @remove()

  # Used to display server-side errors when saving/updating the model.
  errorAlert: (message) ->
    alert = fromMustacheTemplate "standard-error-alert",
      content: message

    @$(".x-alert-container").append alert

  doSave: ->
    b = @$(".x-save").button("loading")

    @model.save null,
      error: (model, response) =>
        b.button("reset")
        @errorAlert response.responseText or response.statusText

      success: (model, response) =>
        b.button("reset")
        @remove()
        insert = @originalModel.isNew()

        # Copy stuff over to the original mode
        @originalModel.set @model

        # Add to top of collection if was new (otherwise
        # it must already be in place inside the collection).
        if insert
          @collection.add new Quiz(@originalModel), at: 0

  events:
    "click .x-cancel" : "doCancel"
    "click .x-save" : "doSave"


QuizFieldsEditorView = FormView.extend
  initialize: ->
    @$el.html readTemplate "quiz-fields-view"
    @linkField "title", null,
      required: "A title for the quiz is required"
    @linkField "location"

# Manages the QuizRoundEditorViews for the rounds collection of the
# Quiz model. Also includes a control to add new Quiz rounds.
QuizRoundsEditorView = View.extend
  initialize: ->
    @$el.html readTemplate "rounds-editor"


NormalRoundView = FormView.extend

roundTypeToView =
  normal: NormalRoundView
  challenge: undefined
  wager: undefined


# Now some page-load-time initialization:

jQuery ->

  displayFirstTab()

  new QuizTableView
    el: $("#quiz-table-view")
