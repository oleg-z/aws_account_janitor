window.App ||= {}
class App.Settings extends App.Base

  beforeAction: (action) =>
    return

  test_email_settings: () =>
    console.log("updating settings")
    $("#button_test_settings").on 'click submit', ->
        $("#test_settings").val("true")
        return true

  afterAction: (action) =>
    this.test_email_settings()
    return




