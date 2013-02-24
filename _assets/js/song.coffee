window.nep ||= {}

nep.Song = Backbone.Model.extend
  defaults: ->
    name: ""
    position: @collection.next()

  reposition: (index) ->
    $("#song_#{@id}").siblings().each ->
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
    'keypress': 'onkeypress'
    'click': 'onclick'
  initialize: ->
    @draggable = false
    @deletable = true
    @render()
  render: ->
    this.$el.html(this.model.attributes.name)
    this.$el.data 'id', this.model.attributes.id
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
      @clone = @$el.clone().attr('id','').addClass("clone").insertAfter(@el)
      @$el.addClass('is_dragging')
      @$el.css('top', @clone.offset().top)
      @draggable = true
    , 150)

  ontouchmove:(e) ->
    @deltaX = e.touches[0].pageX - @start.pageX
    @deltaT = Number(new Date() ) - @start.time
    if @deltaT < 150 && Math.abs(@deltaX) > 50
      window.clearTimeout @timer
      @delete()
    return unless @draggable
    e.preventDefault()
    @last = if @deltaY? then @deltaY else 0
    @deltaY = e.touches[0].pageY - @start.pageY
    if @last > @deltaY
      @direction = "up"
    else if @last < @deltaY
      @direction = "down"
    else
      @direction = null
    transform = "translate3d(0,#{@deltaY}px,0) scale(1.025)"
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
    window.clearTimeout @timer
    return unless @draggable
    e.preventDefault()
    @$el.removeClass('is_dragging').css('top','0').insertAfter(@clone)
    @clone.remove()
    $(".clone").remove()
    @el.style.webkitTransform = ""
    @model.collection.repositionAll()
    @draggable = false

  onkeypress: (e) ->
    return unless e.keyCode == 13
    @done()

  onclick: (e) ->
    e.preventDefault()
    e.stopPropagation()

  edit: ->
    @input = $("<input type='text'>")
    @input.appendTo(@$el).focus().on("blur", => @done())

  done: ->
    name = @input.val()
    if name.length < 1
      @model.destroy()
    else
      @model.set("name", name)
      @model.save()
      @render()

  delete: ->
    return unless @deletable
    @deletable = false
    @$el.addClass('is_deleting').one "webkitTransitionEnd", =>
      @model.destroy()
      $('.is_deleting').remove()

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
    @repositionOne(songItem,i) for songItem, i in @view.$el.children()

  repositionOne: (songItem, i) ->
    position = i+1
    song = @get(songItem.getAttribute('data-id'))
    song.set('position',position).save()

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
    li.edit() if li.model.attributes.name.length == 0

  remove: (song) ->
    $("#song_#{song.id}").remove()
