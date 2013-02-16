window.nep ||= {}
nep.app = {}

if window.applicationCache?
  window.applicationCache.addEventListener 'updateready', ->
    window.applicationCache.swapCache()
    window.location.reload()

$ ->
  nep.app.list = new nep.SetList
