
if Meteor.isServer
  Rooms = new Mongo.Collection('rooms')
  Messages = new Mongo.Collection('messages')
  publish 'rooms', {ordered:false, cursor:false}, () ->
    docs = {}
    Rooms.find({}).fetch().map (room) -> docs[room._id] = room
    return docs
  publish 'messages', {ordered:false, cursor:false}, (roomId) ->
    docs = {}
    Messages.find({roomId}).fetch().map (msg) -> docs[msg._id] = msg
    return docs

Meteor.methods
  newRoom: (name) ->
    check(name, String)
    if Meteor.isServer
      id = Rooms.insert({name, createdAt: Date.now()})
      refreshPub('rooms')
      return id
  newMsg: (roomId, text) ->
    check(roomId, String)
    check(text, String)
    if Meteor.isServer
      Messages.insert({roomId, text, createdAt: Date.now()})
      refreshPub('messages', roomId)

if Meteor.isClient

  blurOnEnterTab = (e) ->
    if e.key is "Tab" or e.key is "Enter"
      e.preventDefault()
      $(e.target).blur()

  createView = (spec) ->
    React.createFactory(React.createClass(spec))

  {div, input} = React.DOM

  App = createView
    displayName: 'App'

    mixins: [
      React.addons.PureRenderMixin
      React.addons.LinkedStateMixin
    ]

    componentWillMount: ->
      @roomSub = subscribe('rooms')
      @roomSub.onChange (rooms) =>
        rooms = Object.keys(rooms)
          .map((id) -> rooms[id])
          .sort((a,b) -> a.createdAt < b.createdAt)
        @setState({rooms})

    componentWillUnmount: ->
      @roomSub.stop()
      @messagesSub?.stop?()

    setRoom: (roomId) ->
      @messagesSub?.stop?()
      @setState({roomId, messages:[]})
      @messagesSub = subscribe('messages', roomId)
      @messagesSub.onChange (messages) =>
        messages = Object.keys(messages)
          .map((id) -> messages[id])
          .sort((a,b) -> a.createdAt < b.createdAt)
        @setState({messages})

    getInitialState: ->
      rooms: []
      messages :[]
      roomId: null
      newRoomName: ''
      newMsgText: ''

    newRoom: ->
      if @state.newRoomName.length > 0
        Meteor.call 'newRoom', @state.newRoomName, (err, roomId) => @setRoom(roomId)
        @setState({newRoomName:''})

    newMsg: (text) ->
      if @state.newMsgText.length > 0 and @state.roomId
        Meteor.call('newMsg', @state.roomId, @state.newMsgText)
        @setState({newMsgText:''})

    render: ->
      (div {className: 'wrapper'},
        (div {className: 'rooms'},
          (div {className: 'row'},
            (input {
              onKeyDown: blurOnEnterTab
              onBlur: @newRoom
              valueLink: @linkState('newRoomName')
              placeholder: 'NEW ROOM'
            }))
          @state.rooms.map (room) =>
            if @state.roomId is room._id
              (div {
                className: 'row selected'
                key: room._id
              }, room.name)
            else
              (div {
                className: 'row'
                key: room._id
                onClick: => @setRoom(room._id)
              }, room.name)
        )
        (div {className: 'messages'},
          do =>
            if @state.roomId
              (div {className:'row'},
                (input {
                  onKeyDown: blurOnEnterTab
                  onBlur: @newMsg
                  valueLink: @linkState('newMsgText')
                  placeholder: 'NEW MESSAGE'
                }))
          @state.messages.map (msg) ->
            (div {
              key: msg._id,
              className: 'row'
            }, msg.text)
        ))

  Meteor.startup ->
    React.render(App({}), document.body)
