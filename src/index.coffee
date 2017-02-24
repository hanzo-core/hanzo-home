CrowdControl =  require 'crowdcontrol'
akasha =        require 'akasha'
objectAssign =  require 'object-assign'
Tween =         require 'tween.js'
raf =           require 'raf'
d3 =            require 'd3'
$ =             require 'jquery'
Promise =       require 'broken'

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
    rfc3339 = daisho.util.time.rfc3339
    moment = daisho.util.moment

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

        time = moment new Date()
        time.seconds 0
        time.minutes 0
        time.hour 0
        time.add 1, 'day'

        ps = for i in [1..30]
          endTime = time.format rfc3339
          time.subtract 1, 'day'
          startTime = time.format rfc3339

          opts =
            tag: 'order.revenue'
            period: 'hourly'
            after: startTime
            before: endTime

          do(endTime)->
            daisho.client.counter.search opts
              .then (res)->
                return [res.count, endTime]

        Promise.settle ps
          .then (data)->
            console.log 'setted', data
            points = data.map (d)->
              return d.value
            points.sort (a,b)->
              return moment(a[1]).diff moment(b[1])
            daisho.data.set 'hanzo-home.points', points
            daisho.update()

        return @el
      ->

    ms.register 'Home', ->
      ps.show 'home'
