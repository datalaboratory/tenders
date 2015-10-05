app.directive 'map', ->
  restrict: 'E'
  templateNamespace: 'svg'
  scope:
    mapData: '='
    citiesData: '='
    tenders: '='
    fieldColors: '='
    duration: '='
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

    getRegionColor = (region) ->
      regionTenders = $scope.tenders.filter (t) -> t.code is region.properties.region

      if regionTenders.length
        regionFields = []

        _.uniq(_.pluck(regionTenders, 'field')).forEach (d) ->
          fieldTenders = regionTenders.filter (rT) -> rT.field is d
          regionFields.push
            name: d
            overall: d3.sum _.pluck fieldTenders, 'price'
          return

        $scope.fieldColors[_.max(regionFields, 'overall').name]
      else
        '#f0f0f0'

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
    .style 'fill', getRegionColor
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

    return
