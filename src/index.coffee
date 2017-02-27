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
yyyymmdd        = Daisho.util.time.yyyymmdd
numeral         = require 'numeral'

class HanzoHome extends CrowdControl.Views.Form
  tag: 'hanzo-home'
  html: require './templates/home'
  css:  require './css/app'
  configs:
    'filter': []

  counters:[
    ['order.count','Orders']
    ['order.revenue','Sales']
    ['order.shipped.cost','Shipping Costs']
    ['order.shipped.count','Orders Shipped']
    ['order.refunded.amount','Refunds']
    ['order.refunded.count','Full Refunds Issued']
    ['order.returned.count','Returns Issued']
    ['user.count','Users']
    ['subscriber.count','Subscribers']
    ['product.wycZ3j0kFP0JBv.sold','Earbuds Sold']
    ['product.wycZ3j0kFP0JBv.shipped.count','Earbuds Shipped']
    ['product.wycZ3j0kFP0JBv.returned.count','Earbuds Returned']
  ]

  # Update?
  filterHash: ''

  init: ->
    filter = @data.get 'filter'
    if !filter
      @data.set 'filter', [moment('2015-01-01').format(yyyymmdd), moment().format(yyyymmdd)]

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
    @data.set 'summaryChart.0.axis.y.name', 'Amount'
    @data.set 'summaryChart.0.series', 'Sales'
    @data.set 'summaryChart.0.fmt.x', (n)->
      return moment(n).format rfc3339
    @data.set 'summaryChart.0.fmt.y', (n)->
      return n / 100
    @data.set 'summaryChart.0.axis.x.ticks', (n)->
      return moment(n).format 'MM/DD'
    @data.set 'summaryChart.0.axis.y.ticks', (n)->
      return numeral(n).format '$0,0'

    @data.set 'summaryChart.0.tip.x', (n)->
      return moment(n).format 'MM/DD/YYYY'
    @data.set 'summaryChart.0.tip.y', (n)->
      return numeral(n).format '$0,0.00'

    @on 'update', =>
      @refresh()

    super

  refresh: ->
    filter = @data.get 'filter'

    filterHash = JSON.stringify filter
    if @filterHash == filterHash
      return

    @filterHash = filterHash

    for counter in @counters
      # Counters
      @refreshCounter counter[0], counter[1], filter[0], filter[1]

    # Chart
    @refreshChartSeries filter[0], filter[1]

  refreshChartSeries: (startTime, endTime)->
    st = moment startTime
    earliest = moment @parentData.get('orgs')[@parentData.get('activeOrg')].createdAt
    if st.diff(earliest) < 0
      st = earliest

    st.seconds 0
    st.minutes 0
    st.hour 0
    et = moment endTime
    et.seconds 0
    et.minutes 0
    et.hour 0
    et.add 1, 'day'

    ps = null
    models = @data.get 'summaryChart'
    model = models[0]
    xs = []
    ys = []

    if et.diff(st, 'day') <= 1
      time = moment startTime
      ps = for i in [0..23]
        after = time.format rfc3339
        time.add 1, 'hour'
        before = time.format rfc3339

        opts =
          tag: 'order.revenue'
          period: 'hourly'
          after: after
          before: before

        model.xs[i] = xs[i] = time.format rfc3339
        model.ys[i] = ys[i] = 0
        do(i)=>
          @client.counter.search(opts).then (res)->
            ys[i] = res.count
    else
      time = moment endTime
      ps = for i in [Math.min(Math.ceil(et.diff(st, 'day')), 90)-2..0]
        before = time.format rfc3339
        time.subtract 1, 'day'
        after = time.format rfc3339

        opts =
          tag: 'order.revenue'
          period: 'hourly'
          after: after
          before: before

        model.xs[i] = xs[i] = time.format rfc3339
        model.ys[i] = ys[i] = 0
        do(i)=>
          @client.counter.search(opts).then (res)->
            ys[i] = res.count

    Promise.settle ps
      .then (data)=>
        model.xs = xs
        model.ys = ys
        @data.set 'summaryChart', models

        @daisho.update()

    requestAnimationFrame =>
      @update()

  refreshCounter: (tag, name, startTime, endTime)->
    opts =
      tag: tag

    st = moment startTime
    et = moment endTime

    if moment(startTime).format(yyyymmdd)== '2015-01-01' && endTime == moment().format(yyyymmdd)
      opts.period = 'total'
    else if et.diff(st, 'days') >= 31
      opts.period = 'monthy' #ummmm
      opts.after = st.format rfc3339
      opts.before = et.format rfc3339
    else
      opts.period = 'hourly'
      opts.after = st.format rfc3339
      opts.before = et.format rfc3339

    @client.counter.search(opts).then((res)=>
      console.log tag, res
      path = 'counters.' + tag
      v = @data.get path
      if v[0].ys[0] == res.count
        return
      v[0].ys[0] = res.count
      v[0].xs[0] = name
      v[0].series = 'All Time'
      if opts.period != 'total'
        v[0].series = 'From ' + st.format(yyyymmdd) + ' to ' + et.format(yyyymmdd)
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
