app.directive 'map', ->
  restrict: 'E'
  templateUrl: 'templates/directives/map.html'
  templateNamespace: 'svg'
  scope:
    data: '='
    filters: '='
    map: '='
    barChart: '='
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
      code = region.properties.region
      fieldsInfo =
        best: 'None'
        bestValue: 0
        overall: 0

      filteredTenders = $scope.data.tenders.filter (t) ->
        (t.code is code) and
        (if $scope.filters.field then t.field is $scope.filters.fields[$scope.filters.field].name else true) and
        (if $scope.filters.price then $scope.filters.prices[$scope.filters.price].leftLimit <= t.price <= $scope.filters.prices[$scope.filters.price].rightLimit else true) and
        (if $scope.filters.region then t.region is $scope.filters.regions[$scope.filters.region].name else true) and
        (if $scope.barChart.field then t.field is $scope.barChart.field else true) and
        (if $scope.barChart.month isnt undefined and $scope.barChart.year isnt undefined then moment(t.date).month() is $scope.barChart.month and moment(t.date).year() is $scope.barChart.year else true)

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

      fieldsInfo

    paintRegionsByBestField = ->
      regions
      .style 'fill', (d) ->
        $scope.data.colors[getFieldsInfo(d).best]
      .style 'opacity', 1
      return

    paintRegionsBySelectedField = ->
      prices = {}
      _.keys($scope.data.codes).forEach (key) ->
        code = $scope.data.codes[key]
        filteredTenders = $scope.data.tenders.filter (t) ->
          (t.code is code) and
          (if $scope.filters.field then t.field is $scope.filters.fields[$scope.filters.field].name else true) and
          (if $scope.filters.price then $scope.filters.prices[$scope.filters.price].leftLimit <= t.price <= $scope.filters.prices[$scope.filters.price].rightLimit else true) and
          (if $scope.filters.region then t.region is $scope.filters.regions[$scope.filters.region].name else true) and
          (if $scope.barChart.field then t.field is $scope.barChart.field else true) and
          (if $scope.barChart.month isnt undefined and $scope.barChart.year isnt undefined then moment(t.date).month() is $scope.barChart.month and moment(t.date).year() is $scope.barChart.year else true)

        prices[code] = d3.sum _.pluck filteredTenders, 'price'
        return

      opacityScale = d3.scale.linear()
      .domain d3.extent _.values prices
      .range [.3, 1]

      regions
      .style 'fill', (region) ->
        if prices[region.properties.region]
          if $scope.filters.field then $scope.data.colors[$scope.filters.fields[$scope.filters.field].name] else $scope.data.colors[$scope.barChart.field]
        else
          $scope.data.colors['None']
      .style 'opacity', (region) ->
        if prices[region.properties.region]
          opacityScale prices[region.properties.region]
        else
          1
      return

    repaintMap = ->
      if $scope.filters.field or $scope.barChart.field
        paintRegionsBySelectedField()
      else
        paintRegionsByBestField()
      return

    tooltip = d3element.select '.map-tooltip'
    tooltipRegionInfo = tooltip.select '.region-info'
    tooltipFieldInfo = tooltip.select '.field-info'
    tooltipRegionInfoRegion = tooltipRegionInfo.select '.region'
    tooltipRegionInfoValue = tooltipRegionInfo.select '.value'
    tooltipFieldInfoField = tooltipFieldInfo.select '.field'
    tooltipFieldInfoValue = tooltipFieldInfo.select '.value'

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
      unless $scope.filters.region
        $scope.map.region = d.properties.region
      $scope.$apply()

      fieldsInfo = getFieldsInfo d

      tooltipRegionInfoRegion.html _.invert($scope.data.codes)[d.properties.region] + (if fieldsInfo.overall then ':' else '')
      tooltipRegionInfoValue.style('display', if fieldsInfo.overall then '' else 'none').html((fieldsInfo.overall / 1000000).toFixed(1) + ' млн')
      tooltipFieldInfo.style 'display', unless fieldsInfo.best is 'None' or $scope.filters.field then '' else 'none'
      tooltipFieldInfoField.html 'в т.ч. «' + fieldsInfo.best.split(',')[0] + (if fieldsInfo.best.indexOf(',') isnt -1 then '...' else '') + '»:'
      tooltipFieldInfoValue.html (fieldsInfo.bestValue / 1000000).toFixed(1) + ' млн'

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
      $scope.map.region = undefined
      $scope.$apply()

      tooltip.style 'display', ''
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
      repaintMap()
      return
    , true

    return
