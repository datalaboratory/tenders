app.directive 'map', ->
  restrict: 'E'
  templateNamespace: 'svg'
  scope:
    mapData: '='
    citiesData: '='
    tenders: '='
    fieldColors: '='
    duration: '='
    filters: '='
    legend: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    width = 960
    height = 500
    projectionScale = 700
    containerScale = $element.parent().width() / width

    projection = d3.geo.albers()
    .rotate [-105, 0]
    .center [-10, 65]
    .parallels [52, 64]
    .scale projectionScale * containerScale
    .translate [width * containerScale / 2, height * containerScale / 2]

    path = d3.geo.path().projection projection

    getBestField = (region) ->
      bestField = 'None'
      filteredTenders = $scope.tenders.filter (t) ->
        (t.code is region.properties.region) and
        (if $scope.filters.price then $scope.filters.prices[$scope.filters.price].leftLimit <= t.price <= $scope.filters.prices[$scope.filters.price].rightLimit else true) and
        (if $scope.filters.region then t.region is $scope.filters.regions[$scope.filters.region].name else true)

      if filteredTenders.length
        regionFields = []

        _.uniq(_.pluck(filteredTenders, 'field')).forEach (d) ->
          fieldTenders = filteredTenders.filter (fT) -> fT.field is d
          regionFields.push
            name: d
            overall: d3.sum _.pluck fieldTenders, 'price'
          return

        bestField = _.max(regionFields, 'overall').name

      bestField

    svg = d3element.append 'svg'
    .classed 'map', true
    .attr 'width', width * containerScale
    .attr 'height', height * containerScale

    regions = svg.append 'g'
    .classed 'regions', true
    .selectAll 'path'
    .data topojson.feature($scope.mapData, $scope.mapData.objects.russia).features
    .enter()
    .append 'path'
    .classed 'region', true
    .attr 'd', path
    .attr 'id', (d) -> d.properties.region
    .style 'fill', (d) -> $scope.fieldColors[getBestField(d)]
    .style 'opacity', 1

    cities = svg.append 'g'
    .classed 'cities', true
    .selectAll 'g'
    .data $scope.citiesData
    .enter()
    .append 'g'
    .classed 'city', true
    .attr 'transform', (d) -> 'translate(' + projection([d.lon, d.lat]) + ')'

    cities.append 'circle'
    .attr 'r', 1.5
    .style 'fill', '#555'

    cities.append 'text'
    .attr 'x', 2
    .attr 'y', -1
    .text (d) -> d.City
    .style 'fill', '#555'
    .style 'font-size', if containerScale > 1 then '12px' else '10px'

    # Resize
    $scope.$on 'render', ($event) ->
      containerScale = $element.parent().width() / width

      svg.transition()
      .duration $scope.duration
      .attr 'width', width * containerScale
      .attr 'height', height * containerScale

      projection.scale(projectionScale * containerScale).translate([width * containerScale / 2, height * containerScale / 2])

      regions.transition()
      .duration $scope.duration
      .attr 'd', path

      cities.transition()
      .duration $scope.duration
      .attr 'transform', (d) -> 'translate(' + projection([d.lon, d.lat]) + ')'

      cities.selectAll 'text'
      .style 'font-size', if containerScale > 1 then '12px' else '10px'
      return

    # Price filter
    $scope.$watch 'filters.price', ->
      regions.style('fill', (d) -> $scope.fieldColors[getBestField(d)])
      return

    # Region filter
    $scope.$watch 'filters.region', ->
      regions.style('fill', (d) -> $scope.fieldColors[getBestField(d)])
      return

    ###
    # Legend
    $scope.$watch 'legend.field', ->
      regions.transition()
      .duration $scope.duration
      .style 'opacity', (d) ->
        color = d3.select(@).style('fill')
        if $scope.legend.field
          if color is $scope.fieldColors[$scope.legend.field] then 1 else .2
        else
          1
      return
    ###

    return
