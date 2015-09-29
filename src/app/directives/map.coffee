app.directive 'map', ($document) ->
  restrict: 'E'
  templateNamespace: 'svg'
  templateUrl: 'templates/directives/map.html'
  scope:
    mapData: '='
    citiesData: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element
    svg = d3element.select 'svg'

    width = svg.node().getBoundingClientRect().width
    height = svg.node().getBoundingClientRect().height

    projection = d3.geo.albers()
    .rotate [-105, 0]
    .center [-10, 65]
    .parallels [52, 64]
    .scale 700
    .translate [width / 2, height / 2]

    $scope.regions = topojson.feature($scope.mapData, $scope.mapData.objects.russia).features

    $scope.getRegionPath = d3.geo.path().projection projection

    $scope.getRegionStyle = (region) ->
      fill: '#333'
      opacity: .5

    $scope.getCityCoordinates = (city) ->
      projection [city.lon, city.lat]

    return
