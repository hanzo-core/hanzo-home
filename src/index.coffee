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
        if n < 1000
          return numeral(n).format '$0'
        return numeral(n).format '$0a'

      @data.set 'counters.order.revenue.0.fmt.y', currency
      @data.set 'counters.order.shipped.cost.0.fmt.y', currency
      @data.set 'counters.order.refunded.amount.0.fmt.y', currency

    super

  refresh: ->
    for counter in @counters
      @getAndUpdate.apply @, counter
    @update()

  getAndUpdate: (tag, period, name)->
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
      v[0].series || 'All Time'
      @data.set path, v
      @daisho.update()
    ).catch (err)->
      console.log err.stack

HanzoHome.register()

class HanzoHomeGraph extends CrowdControl.Views.View
  tag: 'hanzo-home-graph'
  html: require './templates/graph'
  margin:
    top: 40
    right: 40
    bottom: 50
    left: 70

  init: ->
    super

    @on 'mount', =>
      @svg = svg= d3.select @root
        .select 'svg'

      @g1 = g1 = svg.append 'g'
        .attr 'transform', 'translate(' + @margin.left + ',' + @margin.top + ')'

      @g2 = g1.append 'g'
      @g3 = g1.append 'g'
      @g4 = g1.append 'path'

    @on 'updated', =>
      data = @data.get 'hanzo-home.points'
      if !data
        return

      width = $(@root).parent().width()
      height = 300

      @svg
        .attr 'width', width
        .attr 'height', height

      width -= @margin.left + @margin.right
      height -= @margin.top + @margin.bottom

      x = d3.scaleTime()
        .rangeRound [0, width]

      y = d3.scaleLinear()
        .rangeRound [height, 0]

      parseTime = d3.timeParse '%Y-%m-%dT%H:%M:%S%Z'

      line = d3.line()
        .x (d) -> return x parseTime(d[1])
        .y (d) -> return y d[0]

      x.domain d3.extent data, (d)-> return parseTime d[1]
        .ticks d3.timeDay.every(1)
      y.domain d3.extent data, (d)-> return d[0]

      @g2.attr 'transform', 'translate(0,' + height + ')'
        .call d3.axisBottom(x)

      @g3.call d3.axisLeft(y)
        .append 'text'
        .attr 'fill', '#000'
        .attr 'transform', 'rotate(-90)'
        .attr 'y', 6
        .attr 'dy', '0.71em'
        .attr 'text-anchor', 'end'
        .text 'Price ($)'

      @g4.datum data
        .attr 'fill', 'none'
        .attr 'stroke', 'steelblue'
        .attr 'stroke-linejoin', 'round'
        .attr 'stroke-linecap', 'round'
        .attr 'stroke-width', 1.5
        .attr 'd', line

HanzoHomeGraph.register()

module.exports = class Home
  constructor: (daisho, ps, ms)->
    tag = null
    ps.register 'home',
      ->
        @el = el = document.createElement 'hanzo-home'

        tag = (daisho.mount el)[0]
        return el
      ->
        # time = moment new Date()
        # time.seconds 0
        # time.minutes 0
        # time.hour 0
        # time.add 1, 'day'

        # ps = for i in [1..30]
        #   endTime = time.format rfc3339
        #   time.subtract 1, 'day'
        #   startTime = time.format rfc3339

        #   opts =
        #     tag: 'order.revenue'
        #     period: 'hourly'
        #     after: startTime
        #     before: endTime

        #   do(endTime)->
        #     daisho.client.counter.search opts
        #       .then (res)->
        #         return [res.count, endTime]

        # Promise.settle ps
        #   .then (data)->
        #     console.log 'setted', data
        #     points = data.map (d)->
        #       return d.value
        #     points.sort (a,b)->
        #       return moment(a[1]).diff moment(b[1])
        #     daisho.data.set 'hanzo-home.points', points
        #     daisho.update()

        tag.refresh()
        return @el
      ->

    ms.register 'Home', ->
      ps.show 'home'
