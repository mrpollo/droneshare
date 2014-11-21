class UserDetailPage
  constructor: (userName) ->
    @visitPage(userName)
    @userCard = element findBy.css '.user-card'
    @avatar = element findBy.css '.user-card .avatar img'
    @fullName = element findBy.css '.user-card .user-details h1'

  visitPage: (userName) ->
    browser.get "/user/#{userName}"

  getVehicleAt: (index) ->
    element(findBy.repeater('vehicle in controller.record.vehicles').row(index)).element

  getFullName: ->
    @fullName.getText()

module.exports = UserDetailPage

