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
    $(this).attr('href', "mailto:?subject=Setlist&body=#{encodeURIComponent(songs)}")
