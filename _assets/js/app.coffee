window.nep ||= {}
nep.app = {}

if window.applicationCache?
  window.applicationCache.addEventListener 'updateready', ->
    window.applicationCache.swapCache()
    window.location.reload()

$ ->
  nep.app.list = new nep.SetList
  $("#send a").on 'click', (e) ->
    songs = ""
    $(nep.app.list.models).each ->
      songs += "#{this.attributes.name}\n"
    $(this).attr('href', "mailto:?subject=Set%20List&body=#{encodeURIComponent(songs)}")
  unless Modernizr.touch
    $("#header .sized").append("<h2 style='color: yellow; text-align: center; '>Use a touchscreen!</h2>")
