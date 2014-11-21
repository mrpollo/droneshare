Setup       = require '../setup'
LoginPage   = require './pages/loginPage'
HttpBackend = require('http-backend-proxy')

describe 'login', ->
  beforeEach ->
    Setup.mockUserActions new HttpBackend(browser)

    @urlBase    = 'http://localhost:9001'
    @loginPage  = new LoginPage

  it 'should have email and password fields', ->
    expect(@loginPage.emailField).not.toBeUndefined
    expect(@loginPage.passwordField).not.toBeUndefined

  it 'should login on submit and redirect to index', ->
    @loginPage.fillEmail 'fake+email@gmail.com'
    @loginPage.fillPassword 'password'
    @loginPage.submitForm()
    expect(browser.getCurrentUrl()).not.toEqual "#{@urlBase}/login"
