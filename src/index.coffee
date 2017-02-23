CrowdControl =  require 'crowdcontrol'
akasha =        require 'akasha'
objectAssign =  require 'object-assign'
Tween =         require 'tween.js'
raf =           require 'raf'

animate = (time)->
  raf animate
  Tween.update time

raf animate

class HanzoHome extends CrowdControl.Views.Form
  tag: 'hanzo-home'
  html: require './templates/home'
  css:  require './css/app'
  config: {}
  centsFmtStr: '' # '.00'
  currencyFn: (n)->
    fmtStr = @data.get 'hanzo-home.numberFmtStr'
    fmtStr = '$' + fmtStr + @centsFmtStr
    return @daisho.util.numeral(n / 100).format fmtStr

HanzoHome.register()

class HanzoHomeCounter extends CrowdControl.Views.View
  tag: 'hanzo-home-counter'
  html: require './templates/counter'
  negative: false
  format: (n)->
    if @negative
      n = -n
    return @formatFn n

  formatFn: (n)->
    fmtStr = @data.get 'hanzo-home.numberFmtStr'
    return @daisho.util.numeral(n).format fmtStr

HanzoHomeCounter.register()

module.exports = class Home
  constructor: (daisho, ps, ms)->

    getAndUpdate = (tag, period)->
      opts =
        tag: tag
        period: period

      daisho.client.counter.search(opts).then((res)->
        console.log tag, res
        oldValue = daisho.data.get 'hanzo-home.' + tag
        if oldValue == res.count
          return

        new Tween.Tween
          count: oldValue
        .to
          count: res.count
        .onUpdate ->
          daisho.data.set 'hanzo-home.' + tag, parseInt(@count, 10)
          daisho.update()
        .onComplete ->
          daisho.data.set 'hanzo-home.' + tag, res.count
          daisho.update()
          akasha.set 'hanzo-home', daisho.data.get 'hanzo-home'
        .start()
      ).catch (err)->
        console.log err.stack

    ps.register 'home',
      ->
        @el = el = document.createElement 'hanzo-home'

        data = akasha.get 'hanzo-home'
        data = objectAssign {},
          order:
            count: 0
            revenue: 0
            shipped:
              cost: 0
              count: 0
            refunded:
              amount: 0
              count: 0
            returned:
              count: 0
          user:
            count: 0
          subscriber:
            count: 0
          rangeStr: 'All Time'
          numberFmtStr: '0,0'
        , data

        daisho.data.set 'hanzo-home', data
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
