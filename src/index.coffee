CrowdControl = require 'crowdcontrol'

class HanzoHome extends CrowdControl.Views.Form
  tag: 'hanzo-home'
  html: require './templates/hanzo-home'
  # style: require './css/app'
  config: {}

HanzoHome.register()

module.exports = class Home
  constructor: (daisho, ps, ms)->
    ps.register 'home',
      ->
        @el = el = document.createElement 'hanzo-home'
        daisho.data.set 'hanzo-home', {}
        daisho.mount el
        return el
      ->
        opts =
          tag: 'order.count'
          period: 'total'

        daisho.client.counter.search(opts).then((res)->
          console.log 'order.count', res
          daisho.data.set 'hanzo-home.order.count', res.count
          daisho.update()
        ).catch (err)->
          console.log err.stack

        opts =
          tag: 'user.count'
          period: 'total'

        daisho.client.counter.search(opts).then((res)->
          console.log 'user.count', res
          daisho.data.set 'hanzo-home.user.count', res.count
          daisho.update()
        ).catch (err)->
          console.log err.stack

        opts =
          tag: 'subscriber.count'
          period: 'total'

        daisho.client.counter.search(opts).then((res)->
          console.log 'subscriber.count', res
          daisho.data.set 'hanzo-home.subscriber.count', res.count
          daisho.update()
        ).catch (err)->
          console.log err.stack

        daisho.update()
        return @el
      ->

    ms.register 'Home', ->
      ps.show 'home'
