class LoginPage
  constructor: ->
    @visitPage()
    @emailField = element findBy.css '#inputLogin'
    @passwordField = element findBy.css '#inputPassword'
    @loginButton = element findBy.css '#loginButton'
    @errorMessages = element findBy.css '#errorMessages'
    @successMessages = element findBy.css '#successMessages'

  visitPage: ->
    browser.get '/login'

  fillEmail: (email = '') ->
    @emailField.sendKeys email

  fillPassword: (password = '') ->
    @passwordField.sendKeys password

  submitForm: ->
    @loginButton.click()

  getErrorMessage: ->
    @errorMessages.getText()

  getSuccessMessages: ->
    @successMessages.getText()

module.exports = LoginPage
