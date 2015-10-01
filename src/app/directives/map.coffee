app.directive 'map', ->
  restrict: 'E'
  templateNamespace: 'svg'
  templateUrl: 'templates/directives/map.html'
  scope:
    mapData: '='
    citiesData: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    width = 960
    height = 500
    projectionScale = 700
    containerScale = $element.parent().width() / width

    map = d3element.select '.map'

    map.attr('width', width * containerScale).attr('height', height * containerScale)

    projection = d3.geo.albers()
    .rotate [-105, 0]
    .center [-10, 65]
    .parallels [52, 64]
    .scale projectionScale * containerScale
    .translate [width * containerScale / 2, height * containerScale / 2]

    $scope.regions = topojson.feature($scope.mapData, $scope.mapData.objects.russia).features

    $scope.getRegionPath = d3.geo.path().projection projection

    $scope.getRegionStyle = (region) ->
      fill: '#333'
      opacity: .5

    $scope.getCityCoordinates = (city) ->
      projection [city.lon, city.lat]

    $(window).on 'resize', ->
      containerScale = $element.parent().width() / width
      map.attr('width', width * containerScale).attr('height', height * containerScale)
      projection.scale(projectionScale * containerScale).translate([width * containerScale / 2, height * containerScale / 2])
      $scope.$apply()
      return

    return
