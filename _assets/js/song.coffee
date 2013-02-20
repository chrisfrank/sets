window.nep ||= {}

nep.Song = Backbone.Model.extend
  defaults: ->
    name: ""
    position: @collection.next()

  reposition: ->
    @set 'position', ($("#song_#{@id}").index() + 1)
    @save()

nep.SongView = Backbone.View.extend
  tagName: 'li'
  className: 'song'
  id: ->
    "song_#{this.model.id}"
  events: ->
    'touchstart': 'ontouchstart'
    'touchmove': 'ontouchmove'
    'touchend': 'ontouchend'
  initialize: ->
    @draggable = false
    @render()
  render: ->
    this.$el.html(this.model.attributes.name)
    return this
  destroy: (e) ->
    this.model.destroy()

  ontouchstart: (e) ->
    @start = {
      pageX: e.touches[0].pageX
      pageY: e.touches[0].pageY
      time: Number( new Date() )
    }
    @deltaY = 0
    @timer = window.setTimeout( =>
      @clone = @$el.clone().addClass("clone").insertAfter(@el)
      @$el.addClass('is_dragging')
      @$el.css('top', @clone.offset().top)
      @draggable = true
    , 150)

  ontouchmove:(e) ->
    window.clearTimeout @timer
    return unless @draggable
    @last = if @deltaY? then @deltaY else 0
    @deltaY = e.touches[0].pageY - @start.pageY
    if @last > @deltaY
      @direction = "up"
    else if @last < @deltaY
      @direction = "down"
    else
      @direction = null
    transform = "translate3d(0,#{@deltaY}px,0)"
    @el.style.webkitTransform = transform
    nextElem = @clone.next()
    prevElem = @clone.prev(".song:not(.is_dragging)")
    if @direction == "down"
      if @$el.offset().top >= nextElem.offset()?.top
        @clone.insertAfter nextElem
    else if @direction == "up"
      if @$el.offset().top <= prevElem.offset()?.top
        @clone.insertBefore prevElem

  ontouchend:(e) ->
    return unless @draggable
    e.preventDefault()
    @$el.removeClass('is_dragging').css('top','0').insertAfter(@clone)
    @clone.remove()
    @el.style.webkitTransform = ""
    @model.collection.repositionAll()
    @draggable = false

nep.SetList = Backbone.Collection.extend
  model: nep.Song
  localStorage: new Backbone.LocalStorage "songs"
  initialize: ->
    @view = new nep.SetListView
      collection: this
  comparator: (song) ->
    song.get('position')
  next: ->
    if !this.length
      1
    else
      this.last().get('position') + 1
  repositionAll: ->
    song.reposition() for song in @models

nep.SetListView = Backbone.View.extend
  tagName: "ul"
  className: "setlist"
  events:
    "click": "newSong"

  initialize: ->
    @collection.on "add", @add, @
    @collection.on "remove", @remove, @
    @src =  @srcIndex =  @dstIndex = null
    @render()

  render: ->
    @collection.fetch()
    @add song for song in @collection.models
    $('body').append @el

   newSong: ->
    @collection.add({
      name: ""
    })

  add: (song) ->
    li = new nep.SongView
      model: song
    this.$el.append li.el

  remove: (song) ->
    $("#song_#{song.id}").remove()
