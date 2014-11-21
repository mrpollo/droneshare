@userMock = require './../fixtures/user.json'

module.exports.mockUserActions = (proxy) ->
  proxy.whenGET('/api/v1/auth').respond 200, @userMock
  proxy.whenPOST('/api/v1/auth/login').respond 200, @userMock
  proxy.whenGET(/\/api\/v1\/.*/).passThrough()
