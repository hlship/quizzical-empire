# Just a demonstration; rewrite the existing alert-info into an alert-error
$ ->
  $("div.alert-info")
    .addClass("alert-error")
    .removeClass("alert-info")