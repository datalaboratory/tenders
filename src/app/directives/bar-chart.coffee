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

    tooltip = d3element.append 'div'
    .classed 'bar-chart-tooltip', true
    .style 'display', 'none'

    sectionOne = tooltip.append 'div'
    .classed 'section-one', true

    sectionTwo = tooltip.append 'div'
    .classed 'section-two', true

    tooltipFieldCaption = sectionOne.append 'div'
    .classed 'field-caption', true

    tooltipFieldValue = sectionOne.append 'div'
    .classed 'field-value', true

    tooltipNameValue = sectionTwo.append 'div'
    .classed 'tender-value', true

    tooltipCustomerCaption = sectionTwo.append 'div'
    .classed 'tender-caption', true
    .html 'Заказчик'

    tooltipCustomerValue = sectionTwo.append 'div'
    .classed 'tender-value', true

    tooltipPriceCaption = sectionTwo.append 'div'
    .classed 'tender-caption', true
    .html 'Цена контракта'

    tooltipPriceValue = sectionTwo.append 'div'
    .classed 'tender-value', true

    tooltipDateCaption = sectionTwo.append 'div'
    .classed 'tender-caption', true
    .html 'Дата'

    tooltipDateValue = sectionTwo.append 'div'
    .classed 'tender-value', true

    tooltipOffset = 20

    svg = d3element.append 'svg'
    .classed 'bar-chart', true
    .attr 'width', width
    .attr 'height', height

    svg.append 'g'
    .classed 'axis-caption', true
    .attr 'transform', 'translate(0, 0)'
    .append 'text'
    .classed 'caption', true
    .text 'Суммарный объем контрактов, млн руб.'

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

      caption = monthCaptions.append 'g'
      .classed 'caption', true
      .datum {month: month, year: year}
      .attr 'transform', 'translate(' + ((i - 1) * barWidth + (i - 1) * barGap + barWidth / 2) + ', 0)'
      .on 'mouseover', (d) ->
        $scope.barChart.month = d.month
        $scope.barChart.year = d.year
        $scope.$apply()
        return
      .on 'mouseout', ->
        $scope.barChart.month = undefined
        $scope.barChart.year = undefined
        $scope.$apply()
        return

      caption.append 'rect'
      .attr 'x', -(barWidth + barGap) / 2
      .attr 'width', barWidth + barGap
      .attr 'height', margin.bottom
      .style 'fill', '#fff'

      caption.append 'text'
      .attr 'y', 7
      .text $scope.monthNames[month].short

      if i is 1 or !month
        caption.append 'text'
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

        groupedTenders = _.groupBy tBm.tenders, if $scope.filters.field and $scope.filters.region then 'id' else 'field'

        y = height - margin.bottom
        _.keys(groupedTenders).forEach (key) ->
          field = groupedTenders[key][0].field
          overall = d3.sum _.pluck groupedTenders[key], 'price'
          barHeight = yScale overall
          color = $scope.data.colors[field]
          tender = groupedTenders[key][0]

          bar.append 'rect'
          .classed 'field-rect', true
          .datum tender
          .attr 'y', height - margin.bottom
          .attr 'height', 0
          .attr 'width', barWidth
          .attr 'stroke', '#fff'
          .attr 'stroke-width', if $scope.filters.field and $scope.filters.region then 1 else 0
          .style 'fill', color
          .on 'mouseover', (d) ->
            if $scope.filters.field and $scope.filters.region
              sectionOne.style('display', 'none')
              sectionTwo.style('display', '')
              tooltipNameValue.html(d.name)
              tooltipCustomerValue.html(d.customer)
              tooltipPriceValue.html((d.price / 1000000).toFixed(1) + ' млн')
              tooltipDateValue.html(moment(d.date).format('DD.MM.YY'))
            else if $scope.filters.field
              sectionOne.style('display', 'none')
              sectionTwo.style('display', 'none')
            else
              sectionOne.style('display', '')
              sectionTwo.style('display', 'none')
              tooltipFieldCaption.html(field + ':')
              tooltipFieldValue.html('&nbsp;' + (overall / 1000000).toFixed(1) + ' млн')

            tooltip
            .style 'display', 'block'
            .style 'top', d3.event.pageY + 'px'
            .style 'left', d3.event.pageX + tooltipOffset + 'px'
            return
          .on 'mousemove', ->
            tooltip
            .style 'top', d3.event.pageY + 'px'
            .style 'left', d3.event.pageX + tooltipOffset + 'px'
            return
          .on 'mouseout', ->
            tooltip.style 'display', 'none'
            return
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
