# Create local aliases for values in the Quizzical namespace
{Quiz, Round, RoundCollection, Question, QuizList, isBlank,
  readTemplate,fromMustacheTemplate, FormView, ConfirmDialog} = Quizzical

{View} = Backbone

$ = window.jQuery

displayFirstTab = -> $("#top-level-tabs a:first").tab "show"

QuizTableRowView = View.extend
  tagName: "tr"

  initialize: ->
    @model.on "change", @render, this
    @model.on "destroy", @remove, this

    @template = readTemplate "QuizTableRowView"

  events:
    "click .x-delete": "deleteDialog"
    "click .x-edit": "editQuiz"

  render: ->

    @$el.html Mustache.render @template,
      title: @model.escape "title" or "<em>No Title</em>"
      location: @model.escape "location"
      created: @model.get "created"

    this

  deleteDialog: ->

    title = @model.escape "title"

    dialog = new ConfirmDialog
      title: "Really delete Quiz?"
      body: "<p>Deletion of quiz <strong>#{title}</strong>
 is immediate and can not be undone.</p>"
      label: "Delete Quiz"
      buttonClass: "btn-danger"

    dialog.on "confirm", => @model.destroy()

  editQuiz: ->


    # Get the very latest version of the model, which is useful
    # because it may have changed since the colleciton was loaded, and
    # because the collection uses a truncated view of the data.

    @model.fetch
      error: (model, response) ->
        # TODO: Display a property Backbone alert
        window.alert response.responseText or response.statusText
      success: =>
        new QuizEditorView
          model: @model
          collection: @collection

# Owns the table that displays the current list of Quizzes, including
# the buttons used to create a new quiz, etc.
QuizTableView = View.extend

  initialize: ->

    @quizzes = new QuizList

    @$el.html readTemplate "QuizTableView"

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
      model: quiz
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
# updated at the end.
QuizEditorView = FormView.extend

  className: "tab-pane"

  initialize: ->

    # Keep the original model, to flush changes into at the end, but do
    # everything else in a clone.
    @originalModel = @model
    @model = @model.clone()
    @dirty = false

    tabId = _.uniqueId "quiztab_"

    $("#top-level-tabs > ul").append(
      "<li><a href='##{tabId}' data-toggle='tab'>#{@quizName()}</a></li>")

    # Set the id attribute, read the template containing the form,
    # and move it into place.
    @$el.attr("id", tabId)
      .html(readTemplate "QuizEditorView")
      .appendTo("#top-level-tabs > .tab-content")

    @$(".x-cancel").tooltip()

    @viewTab = $("#top-level-tabs .nav-tabs a:[href='##{tabId}']")

    @viewTab.tab "show"

    $("#top-level-tabs .nav-tabs a:last").tab "show"

    @updateSaveButton()

    @model.on "change:title", @updateTabTitle, this
    @model.on "change childChange", @updateSaveButton, this
    @model.on "change", @triggerDirtyEvent, this
    @model.on "dirty", @markDirty, this

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

  triggerDirtyEvent: -> @model.trigger "dirty"

  markDirty: ->
    @dirty = true
    @$(".x-cancel").addClass "btn-warning"

  remove: ->
    displayFirstTab()

    @$el.remove()

    # And the LI containing the tab's A
    @viewTab.parent().remove()

    # Don't have to worry about model events, since
    # because we cloned the original model

  updateTabTitle: ->
    @viewTab.html @quizName()

  # Disables the save button unless model is valid
  updateSaveButton: ->
    @$(".x-save").attr "disabled", not @model.enableSave()

  # Handles the case, for new models, that the title may be blank.
  quizName: ->
    @model.escape("title") || "<em>New Quiz</em>"

  doCancel: ->
   @$(".x-cancel").tooltip "hide"

   if @dirty
      dialog = new ConfirmDialog
        title: "Discard changes?"
        body: "<p>Changes will be lost. This can not be undone.</p>"
      dialog.on "confirm", @remove, this
    else
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
    "click .x-cancel": "doCancel"
    "click .x-save": "doSave"

QuizFieldsEditorView = FormView.extend
  initialize: ->
    @$el.html readTemplate "QuizFieldsEditorView"

    @linkField name for name in ["title", "location"]

# Manages the QuizRoundEditorViews for the rounds collection of the
# Quiz model. Also includes a control to add new Quiz rounds.
QuizRoundsEditorView = View.extend
  initialize: ->
    @$el.html readTemplate "QuizRoundsEditorView"

    @accordion = @$(".accordion")

    @collection = new RoundCollection @model.get "rounds"

    lastView = null

    headers = @collection.map (round, i) =>
      round.set "index", i + 1
      lastView = @createRoundView round

    lastView? and lastView.show()

    @collection.on "all", =>
      @model.set "rounds", @collection.toArray()
      @model.trigger "childChange"

    @collection.on "add remove", @renumberRounds, this

  createRoundView: (round) ->
    ctor = roundKindToViewClass[round.get("kind")]
    view = new ctor model:round

    header = new RoundHeaderView {
      @collection, @accordion,
      model: round,
      editor: view.$el }

    @accordion.append header.$el

    return header

  addNewRound: (event) ->
    event.preventDefault()
    kind = @$(".x-add-new-round select").val()
    round = new Round
      kind: kind
      index: @collection.length + 1
    @collection.add round

    (@createRoundView round).show()

  renumberRounds: ->
    index = 1
    @collection.each (round) ->
      round.set "index", index++

  events:
    "click .x-add": "addNewRound"

RoundHeaderView = FormView.extend
  initialize: ->
    @$el.html fromMustacheTemplate "RoundHeaderView",
      kind: @model.get "kind"

    # Since we're not using "data-" attributes, we have to wire
    # up a click event handler ourselves, rather than rely on the
    # global listener built into bootstrap-collapse.js
    @body = @$(".accordion-body").collapse
      toggle: false
      parent: @options.accordion

    toggle = @$(".accordian-toggle").tooltip()
    toggle.on "click", (event) =>
      event.preventDefault()
      @body.collapse "toggle"

    @linkElement "index"
    # Can't use defaults since there's two .x-title elements
    @linkElement "title", "span.x-title", "No Title"
    @linkField "title", ".control-group.x-title"

    @$(".x-editor").html @options.editor

  hide: ->
    @body.collapse "hide"

  show: ->
    @body.collapse "show"


  events:
    "click .accordion-heading .x-delete": "doDelete"

  doDelete: (event) ->
    event.preventDefault()

    dialog = new ConfirmDialog
      title: "Really delete?"
      body: "<p>The entire round will be deleted, along with all questions.</p>"
      label: "Delete Round"
      buttonClass: "btn-danger"

    dialog.on "confirm", =>
      @remove()
      @collection.remove @model

NormalRoundEditView = FormView.extend
  initialize: ->
    @$el.html readTemplate "NormalRoundEditView"

 roundKindToViewClass =
  normal: NormalRoundEditView
  challenge: undefined
  wager: undefined


# Now some page-load-time initialization:

jQuery ->

  displayFirstTab()

  new QuizTableView
    el: $("#quiz-table-view")
