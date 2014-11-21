Setup           = require '../setup'
HttpBackend     = require('http-backend-proxy')
UserDetailPage  = require './../shared/pages/userDetailPage'

describe 'user detail view', ->
  beforeEach ->
    Setup.mockUserActions new HttpBackend(browser)
    @userDetailPage = new UserDetailPage('mrpollo')

  describe 'user info', ->
    it 'should have a name', ->
      expect(@userDetailPage.fullName).not.toBeUndefined

    it 'should match the mocked name', ->
      expect(@userDetailPage.getFullName()).toEqual 'Ramón Roche'
