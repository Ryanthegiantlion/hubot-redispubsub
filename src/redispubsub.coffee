redis = require('redis');
RedisChannels = require('./constants/redisChannels')
utilities = require('./utilities')

try
  {Robot,Adapter,TextMessage,User} = require 'hubot'
catch
  prequire = require('parent-require')
  {Robot,Adapter,TextMessage,User} = prequire 'hubot'

class Redispubsub extends Adapter

  constructor: ->
    super
    # @userId = '57be6070296ad1b878399281'
    @userId = '57be9d4b741f998795f31b62'
    @botname = 'simplebot'
    if process.env.REDIS_URL
      @redisSub = redis.createClient process.env.REDIS_URL
      @redisPub = redis.createClient process.env.REDIS_URL
    else
      @redisSub = redis.createClient()
      @redisPub = redis.createClient()
    @allMessages = {}
    @robot.logger.info "Constructor"

  send: (envelope, strings...) ->
    @robot.logger.info "Send"
    @robot.logger.info envelope
    @robot.logger.info ''
    @robot.logger.info strings
    received_message = @allMessages[envelope.message.id]
    @robot.logger.info 'here'
    @robot.logger.info received_message
    for s in strings
      # not sure why send is being hit rather than resply when it is actually
      # a reply but w/e
      if received_message.type == 'Group'
        new_message = @newPubSubGroupMessage(received_message, s)
      else
        new_message = @newPubSubDirectMessage(received_message, s)
      @redisPub.publish RedisChannels.BotReply, JSON.stringify(new_message)
      @robot.logger.info new_message
      @robot.logger.info 'sending group message'

  reply: (envelope, strings...) ->
    @robot.logger.info "Reply"
    @robot.logger.info envelope
    @robot.logger.info ''
    @robot.logger.info strings
    received_message = @allMessages[envelope.message.id]
    for s in strings
      # not sure why send is being hit rather than resply when it is actually
      # a reply but w/e
      if received_message.type == 'Group'
        new_message = @newPubSubGroupMessage(received_message, s)
      else
        new_message = @newPubSubDirectMessage(received_message, s)      
      @redisPub.publish RedisChannels.BotReply, JSON.stringify(new_message)
      @robot.logger.info new_message
      @robot.logger.info 'sending dm'
    # @robot.logger.info 'here'
    # @robot.logger.info received_message

  onMessage: (channel, data) =>
    @robot.logger.info 'getting messages'
    @robot.logger.info channel
    @robot.logger.info data
    data = JSON.parse data
    # TODO This is currently only being cleaned up in send and reply
    # Need to also clean this up when it isnt matched
    @allMessages[data.clientMessageIdentifier] = data;

    user = new User data.senderId, name: data.senderName
    if data.type == 'Group'
      message = new TextMessage user, data.body.text, data.clientMessageIdentifier
    else
      message = new TextMessage user, @botname + ' ' + data.body.text, data.clientMessageIdentifier
    
    @robot.logger.info 'here'
    @robot.logger.info message
    @robot.receive message

  newPubSubGroupMessage: (received_message, response) ->
    if /(png|jpg|gif|bmp)$/.test(response)
      new_body = 
        type: 'Image'
        url: response
    else
      new_body =
        type: 'TextMessage'
        text: response

    new_props = 
      senderId: @userId
      senderName: @botname
      body: new_body
      clientMessageIdentifier: utilities.guid()
      clientStartTime: new Date()

    new_message = Object.assign received_message, new_props

    return new_message

  newPubSubDirectMessage: (received_message, response) ->
    if /(png|jpg|gif|bmp)$/.test(response)
      new_body = 
        type: 'Image'
        url: response
    else
      new_body =
        type: 'TextMessage'
        text: response

    new_props = 
      senderId: @userId
      senderName: @botname
      receiverId: received_message.senderId
      receiverName: received_message.senderName
      body: new_body
      clientMessageIdentifier: utilities.guid()
      clientStartTime: new Date()
      
    new_message = Object.assign received_message, new_props

    return new_message

  run: ->
    @robot.logger.info "Run"
    
    @redisSub.subscribe(RedisChannels.BotMessage)
    @redisSub.on 'message', @onMessage

    @emit "connected"
    # user = new User 1001, name: 'Sample User'
    # message = new TextMessage user, 'can we have a badger please', 'MSG-001'
    # @robot.receive message
    # directmessage = new TextMessage user, 'simplebot hi', 'MSG-001'
    # @robot.receive directmessage
    # @robot.logger.info 'Message Received'


exports.use = (robot) ->
  new Redispubsub robot