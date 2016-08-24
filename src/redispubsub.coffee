try
  {Robot,Adapter,TextMessage,User} = require 'hubot'
catch
  prequire = require('parent-require')
  {Robot,Adapter,TextMessage,User} = prequire 'hubot'

class Redispubsub extends Adapter

  constructor: ->
    super
    @robot.logger.info "Constructor"

  send: (envelope, strings...) ->
    @robot.logger.info "Send"

  reply: (envelope, strings...) ->
    @robot.logger.info "Reply"

  run: ->
    @robot.logger.info "Run"
    @emit "connected"
    user = new User 1001, name: 'Sample User'
    message = new TextMessage user, 'can we have a badger please', 'MSG-001'
    @robot.receive message
    directmessage = new TextMessage user, 'simplebot hi', 'MSG-001'
    @robot.receive directmessage
    @robot.logger.info 'Message Received'


exports.use = (robot) ->
  new Redispubsub robot