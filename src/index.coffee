CrowdControl    = require 'crowdcontrol'
Promise         = require 'broken'
Daisho          = require 'daisho'
akasha          = require 'akasha'
objectAssign    = require 'object-assign'
raf             = require 'raf'
d3              = require 'd3'
$               = require 'jquery'
moment          = require 'moment-timezone'
rfc3339         = Daisho.util.time.rfc3339
numeral         = require 'numeral'

class HanzoHome extends CrowdControl.Views.Form
  tag: 'hanzo-home'
  html: require './templates/home'
  css:  require './css/app'
  config: {}
  counters:[
    ['order.count', 'total', 'Orders']
    ['order.revenue', 'total', 'Sales']
    ['order.shipped.cost', 'total', 'Shipping Costs']
    ['order.shipped.count', 'total', 'Orders Shipped']
    ['order.refunded.amount', 'total', 'Refunds']
    ['order.refunded.count', 'total', 'Full Refunds Issued']
    ['order.returned.count', 'total', 'Returns Issued']
    ['user.count', 'total', 'Users']
    ['subscriber.count', 'total', 'Subscribers']
    ['product.wycZ3j0kFP0JBv.sold', 'total', 'Earbuds Sold']
    ['product.wycZ3j0kFP0JBv.shipped.count', 'total', 'Earbuds Shipped']
    ['product.wycZ3j0kFP0JBv.returned.count', 'total', 'Earbuds Returned']
  ]

  init: ->
    data = akasha.get 'counters'
    data = objectAssign {}, data
    for counter in @counters
      models = Daisho.Graphics.Model.new()
      for model in models
        model.fmt.y = (n)->
          return parseInt n, 10
      @data.set 'counters.' + counter[0], models

      currency = (n)->
        n = n / 100
        # if n < 1000
        #   return numeral(n).format '$0a'
        return numeral(n).format '$0,0'

      @data.set 'counters.order.revenue.0.fmt.y', currency
      @data.set 'counters.order.shipped.cost.0.fmt.y', currency
      @data.set 'counters.order.refunded.amount.0.fmt.y', currency

    @data.set 'summaryChart', Daisho.Graphics.Model.new()
    @data.set 'summaryChart.0.axis.x.name', 'Date'
    @data.set 'summaryChart.0.axis.y.name', 'Amount(USD)'
    @data.set 'summaryChart.0.fmt.y', (n)->
      return n / 100
    @data.set 'summaryChart.0.axis.y.ticks', (n)->
      return numeral(n).format '$0,0'

    super

  refresh: ->
    for counter in @counters
      # Counters
      @refreshCounter.apply @, counter

    # Chart
    time = moment new Date()
    time.seconds 0
    time.minutes 0
    time.hour 0
    time.add 1, 'day'

    model = @data.get('summaryChart')[0]
    model.xs = []
    model.ys = []

    ps = for i in [0..29]
      endTime = time.format rfc3339
      time.subtract 1, 'day'
      startTime = time.format rfc3339

      opts =
        tag: 'order.revenue'
        period: 'hourly'
        after: startTime
        before: endTime

      model.xs[i] = endTime
      do(i)=>
        @client.counter.search(opts).then (res)->
          model.ys[i] = res.count

    Promise.settle ps
      .then (data)=>
        @data.set 'summaryChart', [model]
        @update()

    @update()

  refreshCounter: (tag, period, name)->
    opts =
      tag: tag
      period: period

    @client.counter.search(opts).then((res)=>
      console.log tag, res
      path = 'counters.' + tag
      v = @data.get path
      if v[0].ys[0] == res.count
        return
      v[0].ys[0] = res.count
      v[0].xs[0] = name
      v[0].series = 'All Time'
      if period != 'total'
        v[0].series = tag.after + ' ' + tag.before
      @data.set path, v
      @daisho.update()
    ).catch (err)->
      console.log err.stack

HanzoHome.register()

module.exports = class Home
  constructor: (daisho, ps, ms)->
    tag = null
    ps.register 'home',
      ->
        @el = el = document.createElement 'hanzo-home'

        tag = (daisho.mount el)[0]
        return el
      ->
        tag.refresh()
        return @el
      ->

    ms.register 'Home', ->
      ps.show 'home'
