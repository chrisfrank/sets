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
    "click": "edit"
    "keypress input": "done"
    "swipeleft": "delete"
  initialize: ->
    @render()

  render: ->
    this.$el.html("<input autocorrect='none' type='text' " +
      "value='#{this.model.attributes.name}'/>" +
      "<i class='icon-handle'></i>").hammer()
    return this

  edit: (e) ->
    e.stopPropagation()
    this.$el.addClass('is_editing').find('input').focus()

  done: (e) ->
    e.stopPropagation()
    if e.keyCode == 13
      name = this.$el.find('input').val()
      this.model.set('name', name).save()
      this.render().$el.removeClass('is_editing')

  delete: (e) ->
    this.model.destroy()

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
    @$el.dragdrop
      dragClass: "is_dragging"
      makeClone: true
      sourceHide: true
      canDrag: ($src, event) =>
        $t = $(event.target)
        if $t.hasClass('icon-handle')
          @src = $t.closest('li')
          @srcIndex = @src.index()
          @dstIndex = @srcIndex
          return @src
        else
          return null
      canDrop: ($dst) =>
        if $dst.is "li"
          @dstIndex = $dst.index()
          if @srcIndex < @dstIndex
            @src.insertAfter $dst
          else
            @src.insertBefore $dst
          true
        else
          true
      didDrop: ($src, $dst) =>
        @collection.repositionAll()

  newSong: ->
    @collection.add({
      name: ""
    })
    $("li").last().trigger 'click'

  add: (song) ->
    li = new nep.SongView
      model: song
    this.$el.append li.el

  remove: (song) ->
    $("#song_#{song.id}").slideUp ->
      $(this).remove()
