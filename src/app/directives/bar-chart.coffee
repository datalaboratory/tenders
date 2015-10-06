app.directive 'barChart', ->
  restrict: 'E'
  templateNamespace: 'svg'
  scope:
    data: '='
    startDate: '='
    endDate: '='
    filters: '='
    map: '='
    barChart: '='
    monthNames: '='
    duration: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    width = $element.parent().width()
    height = $scope.map.height
    margin =
      top: 40
      right: 0
      bottom: 30
      left: 0

    nOfMonths = moment($scope.endDate).diff(moment($scope.startDate), 'months')
    barGap = width * .01
    barWidth = (width - (nOfMonths - 1) * barGap) / nOfMonths

    svg = d3element.append 'svg'
    .classed 'bar-chart', true
    .attr 'width', width
    .attr 'height', height

    svg.append 'g'
    .classed 'axis-caption', true
    .attr 'transform', 'translate(0, 0)'
    .append 'text'
    .classed 'caption', true
    .text 'Сумма цен контрактов, млн руб.'

    monthCaptions = svg.append 'g'
    .classed 'month-captions', true
    .attr 'transform', 'translate(0, ' + (height - margin.bottom) + ')'

    bars = svg.append 'g'
    .classed 'bars', true

    i = 1
    while i < nOfMonths + 1
      date = moment($scope.startDate).add(i, 'M')
      month = date.month()
      year = date.year()
      caption = $scope.monthNames[month].short

      monthCaptions.append 'text'
      .classed 'caption', true
      .attr 'x', (i - 1) * barWidth + (i - 1) * barGap + barWidth / 2
      .attr 'y', 7
      .text caption

      if i is 1 or !month
        monthCaptions.append 'text'
        .classed 'caption', true
        .attr 'x', (i - 1) * barWidth + (i - 1) * barGap + barWidth / 2
        .attr 'y', 20
        .text year

      i++

    drawBars = ->
      bars.selectAll('*').remove()

      tendersByMonth = []

      i = 1
      while i < nOfMonths + 1
        date = moment($scope.startDate).add(i, 'M')
        month = date.month()
        year = date.year()

        filteredTenders = $scope.data.tenders.filter (t) ->
          (moment(t.date).month() is month and moment(t.date).year() is year) and
          (if $scope.filters.field then t.field is $scope.filters.fields[$scope.filters.field].name else true) and
          (if $scope.filters.price then $scope.filters.prices[$scope.filters.price].leftLimit <= t.price <= $scope.filters.prices[$scope.filters.price].rightLimit else true) and
          (if $scope.filters.region then t.region is $scope.filters.regions[$scope.filters.region].name else true) and
          (if $scope.map.region then t.code is $scope.map.region else true)

        tendersByMonth.push
          month: month
          year: year
          tenders: filteredTenders
          overall: d3.sum(_.pluck(filteredTenders, 'price'))

        i++

      yScale = d3.scale.linear()
      .domain [0, d3.max(_.pluck(tendersByMonth, 'overall'))]
      .range [0, height - margin.top - margin.bottom]

      tendersByMonth.forEach (tBm, i) ->
        bar = bars.append 'g'
        .classed 'bar', true
        .attr 'transform', 'translate(' + (i * barWidth + i * barGap) + ', 0)'
        .on 'mouseover', ->
          $scope.barChart.month = tBm.month
          $scope.barChart.year = tBm.year
          $scope.$apply()
          return
        .on 'mouseout', ->
          $scope.barChart.month = undefined
          $scope.barChart.year = undefined
          $scope.$apply()
          return

        groupedTenders = _.groupBy tBm.tenders, if $scope.filters.field then 'id' else 'field'

        y = height - margin.bottom
        _.keys(groupedTenders).forEach (key) ->
          barHeight = yScale d3.sum _.pluck groupedTenders[key], 'price'
          color = $scope.data.colors[groupedTenders[key][0].field]

          bar.append 'rect'
          .classed 'field-rect', true
          .attr 'y', height - margin.bottom
          .attr 'height', 0
          .attr 'width', barWidth
          .style 'fill', color
          .transition()
          .duration $scope.duration
          .attr 'y', y - barHeight
          .attr 'height', barHeight

          y -= barHeight
          return

        if tBm.overall
          bar.append 'text'
          .classed 'caption', true
          .attr 'x', barWidth / 2
          .attr 'y', height - margin.bottom - yScale(tBm.overall) - 10
          .text (tBm.overall / 1000000).toFixed(1)
          .style 'opacity', 0
          .transition()
          .duration $scope.duration
          .style 'opacity', 1
        return
      return

    # Field filter
    $scope.$watch 'filters.field', -> drawBars()

    # Price filter
    $scope.$watch 'filters.price', -> drawBars()

    # Region filter
    $scope.$watch 'filters.region', -> drawBars()

    # Map region mouseover
    $scope.$watch 'map.region', -> drawBars()

    return
