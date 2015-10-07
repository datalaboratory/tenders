app.directive 'map', ->
  restrict: 'E'
  templateNamespace: 'svg'
  scope:
    data: '='
    filters: '='
    map: '='
    barChart: '='
    legend: '='
    duration: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    initialWidth = 960
    initialHeight = 500
    initialScale = 700

    ratio = $element.parent().width() / initialWidth

    $scope.map.width = initialWidth * ratio
    $scope.map.height = initialHeight * ratio

    projection = d3.geo.albers()
    .rotate [-105, 0]
    .center [-10, 65]
    .parallels [52, 64]
    .scale initialScale * ratio
    .translate [$scope.map.width / 2, $scope.map.height / 2]

    path = d3.geo.path().projection projection

    getFieldsInfo = (region) ->
      fieldsInfo =
        best: 'None'
        bestValue: 0
        overall: 0

      filteredTenders = $scope.data.tenders.filter (t) ->
        (t.code is region.properties.region) and
        (if $scope.filters.field then t.field is $scope.filters.fields[$scope.filters.field].name else true) and
        (if $scope.filters.price then $scope.filters.prices[$scope.filters.price].leftLimit <= t.price <= $scope.filters.prices[$scope.filters.price].rightLimit else true) and
        (if $scope.filters.region then t.region is $scope.filters.regions[$scope.filters.region].name else true) and
        (if $scope.barChart.month and $scope.barChart.year then moment(t.date).month() is $scope.barChart.month and moment(t.date).year() is $scope.barChart.year else true)

      if filteredTenders.length
        regionFields = []

        _.uniq(_.pluck(filteredTenders, 'field')).forEach (d) ->
          fieldTenders = filteredTenders.filter (fT) -> fT.field is d
          regionFields.push
            name: d
            value: d3.sum _.pluck fieldTenders, 'price'
          return

        fieldsInfo.best =  _.max(regionFields, 'value').name
        fieldsInfo.bestValue = _.max(regionFields, 'value').value
        fieldsInfo.overall = d3.sum _.pluck regionFields, 'value'

        if $scope.legend.fields.indexOf(fieldsInfo.best) is -1
          $scope.legend.fields.push fieldsInfo.best

      fieldsInfo

    paintRegionsByBestField = ->
      $scope.legend.fields = []
      regions.style 'fill', (d) ->
        $scope.data.colors[getFieldsInfo(d).best]
      .style 'opacity', 1
      return

    paintRegionsBySelectedField = ->
      $scope.legend.fields = [$scope.filters.fields[$scope.filters.field].name]
      prices = {}
      regions[0].forEach (d) ->
        region = d.__data__
        filteredTenders = $scope.data.tenders.filter (t) ->
          (t.code is region.properties.region) and
          (t.field is $scope.filters.fields[$scope.filters.field].name) and
          (if $scope.filters.price then $scope.filters.prices[$scope.filters.price].leftLimit <= t.price <= $scope.filters.prices[$scope.filters.price].rightLimit else true) and
          (if $scope.filters.region then t.region is $scope.filters.regions[$scope.filters.region].name else true) and
          (if $scope.barChart.month and $scope.barChart.year then moment(t.date).month() is $scope.barChart.month and moment(t.date).year() is $scope.barChart.year else true)

        prices[region.properties.region] = d3.sum _.pluck filteredTenders, 'price'
        return

      opacityScale = d3.scale.linear()
      .domain d3.extent _.values prices
      .range [.3, 1]

      regions.style 'fill', (region) ->
        if prices[region.properties.region]
          $scope.data.colors[$scope.filters.fields[$scope.filters.field].name]
        else
          $scope.data.colors['None']
      .style 'opacity', (region) ->
        if prices[region.properties.region]
          opacityScale prices[region.properties.region]
        else
          1
      return

    repaintMap = ->
      if $scope.filters.field
        paintRegionsBySelectedField()
      else
        paintRegionsByBestField()
      return

    tooltip = d3element.append 'div'
    .classed 'map-tooltip', true
    .style 'display', 'none'

    sectionOne = tooltip.append 'div'
    sectionTwo = tooltip.append 'div'

    tooltipRegion = sectionOne.append 'div'
    .classed 'region', true

    tooltipRegionValue = sectionOne.append 'div'
    .classed 'region value', true

    tooltipField = sectionTwo.append 'div'
    .classed 'field', true

    tooltipFieldValue = sectionTwo.append 'div'
    .classed 'field value', true

    tooltipOffset = 20
    windowWidth = $(window).width()

    svg = d3element.append 'svg'
    .classed 'map', true
    .attr 'width', $scope.map.width
    .attr 'height', $scope.map.height

    regions = svg.append 'g'
    .classed 'regions', true
    .selectAll 'path'
    .data topojson.feature($scope.data.regions, $scope.data.regions.objects.russia).features
    .enter()
    .append 'path'
    .classed 'region', true
    .attr 'd', path
    .attr 'id', (d) -> d.properties.region
    .style 'fill', (d) -> $scope.data.colors[getFieldsInfo(d).best]
    .style 'stroke', '#f1f1f1'
    .style 'stroke-width', .5
    .style 'opacity', 1
    .on 'mouseover', (d) ->
      $scope.map.color = d3.select(@).style('fill')
      unless $scope.filters.region
        $scope.map.region = d.properties.region
      $scope.$apply()

      fieldsInfo = getFieldsInfo d

      tooltipRegion.html(_.invert($scope.data.codes)[d.properties.region] + if fieldsInfo.overall then ':' else '')
      tooltipRegionValue.style('display', if fieldsInfo.overall then '' else 'none').html('&nbsp;' + (fieldsInfo.overall / 1000000).toFixed(1) + ' млн')
      sectionTwo.style('display', unless fieldsInfo.best is 'None' or $scope.filters.field then '' else 'none')
      tooltipField.html('в т.ч. «' + (fieldsInfo.best.split(',')[0]) + (if fieldsInfo.best.indexOf(',') isnt -1 then '...' else '') + '»:')
      tooltipFieldValue.html('&nbsp;' + (fieldsInfo.bestValue / 1000000).toFixed(1) + ' млн')

      tooltipWidth = tooltip.node().getBoundingClientRect().width
      tootlipHeight = tooltip.node().getBoundingClientRect().height

      tooltip
      .style 'display', 'block'
      .style 'top', d3.event.pageY + 'px'
      .style 'left', if d3.event.pageX + tooltipWidth + tooltipOffset > windowWidth then d3.event.pageX - tooltipWidth - tooltipOffset + 'px' else d3.event.pageX + tooltipOffset + 'px'
      return
    .on 'mousemove', ->
      tooltipWidth = tooltip.node().getBoundingClientRect().width
      tootlipHeight = tooltip.node().getBoundingClientRect().height

      tooltip
      .style 'top', d3.event.pageY + 'px'
      .style 'left', if d3.event.pageX + tooltipWidth + tooltipOffset > windowWidth then d3.event.pageX - tooltipWidth - tooltipOffset + 'px' else d3.event.pageX + tooltipOffset + 'px'
      return
    .on 'mouseout', ->
      $scope.map.color = undefined
      $scope.map.region = undefined
      $scope.$apply()

      tooltip.style 'display', 'none'
      return

    cities = svg.append 'g'
    .classed 'cities', true
    .selectAll 'g'
    .data $scope.data.cities
    .enter()
    .append 'g'
    .classed 'city', true
    .attr 'transform', (d) -> 'translate(' + projection([d.lon, d.lat]) + ')'

    cities.append 'circle'
    .attr 'r', 1.5
    .style 'fill', '#555'

    cities.append 'text'
    .classed 'text-background', true
    .attr 'x', 2
    .attr 'y', -1
    .text (d) -> d.City
    .style 'font-size', if ratio > 1 then '12px' else '10px'

    cities.append 'text'
    .attr 'x', 2
    .attr 'y', -1
    .text (d) -> d.City
    .style 'fill', '#555'
    .style 'font-size', if ratio > 1 then '12px' else '10px'

    # Field filter
    $scope.$watch 'filters.field', -> repaintMap()

    # Price filter
    $scope.$watch 'filters.price', -> repaintMap()

    # Region filter
    $scope.$watch 'filters.region', -> repaintMap()

    # Month mouseover
    $scope.$watch 'barChart', ->
      console.log $scope.barChart.month, $scope.barChart.year
      repaintMap()
      return
    , true

    # Legend
    $scope.$watch 'legend.field', ->
      regions.transition()
      .duration $scope.duration
      .style 'opacity', (d) ->
        color = d3.select(@).style('fill')
        if $scope.legend.field
          if color is $scope.data.colors[$scope.legend.field] then 1 else .2
        else
          1
      return

    return
