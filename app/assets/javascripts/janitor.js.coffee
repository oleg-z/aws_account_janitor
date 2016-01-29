window.App ||= {}
class App.Janitor extends App.Base

  beforeAction: (action) =>
    return

  bind_select_all_checkbox: () =>
    $("input.select-all").on 'change', ->
        console.log("on change")
        console.log($(this).attr('checked'))
        $(this).parent("table").find(".mass-selector").attr('checked', $(this).attr('checked'))

  afterAction: (action) =>
    this.bind_select_all_checkbox()
    return
