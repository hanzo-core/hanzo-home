CrowdControl = require 'crowdcontrol'
akasha = require 'akasha'

class HanzoHome extends CrowdControl.Views.Form
  tag: 'hanzo-home'
  html: require './templates/hanzo-home'
  # style: require './css/app'
  config: {}

HanzoHome.register()

module.exports = class Home
  constructor: (daisho, ps, ms)->

    getAndUpdate = (tag, period)->
      opts =
        tag: tag
        period: period

      daisho.client.counter.search(opts).then((res)->
        console.log tag, res
        daisho.data.set 'hanzo-home.' + tag, res.count
        akasha.set 'hanzo-home', daisho.data.get 'hanzo-home'
        daisho.update()
      ).catch (err)->
        console.log err.stack

    ps.register 'home',
      ->
        @el = el = document.createElement 'hanzo-home'

        data = akasha.get 'hanzo-home'
        daisho.data.set 'hanzo-home', (data || {})
        daisho.mount el
        return el
      ->
        getAndUpdate 'order.count', 'total'
        getAndUpdate 'order.revenue', 'total'
        getAndUpdate 'order.shipped.cost', 'total'
        getAndUpdate 'order.shipped.count', 'total'
        getAndUpdate 'order.refunded.amount', 'total'
        getAndUpdate 'order.refunded.count', 'total'
        getAndUpdate 'order.returned.count', 'total'
        getAndUpdate 'user.count', 'total'
        getAndUpdate 'subscriber.count', 'total'
        getAndUpdate 'product.wycZ3j0kFP0JBv.sold', 'total'
        getAndUpdate 'product.wycZ3j0kFP0JBv.shipped.count', 'total'
        getAndUpdate 'product.wycZ3j0kFP0JBv.returned.count', 'total'

        return @el
      ->

    ms.register 'Home', ->
      ps.show 'home'
