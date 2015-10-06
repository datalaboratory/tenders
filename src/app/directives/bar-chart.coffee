app.directive 'barChart', ->
  restrict: 'E'
  templateNamespace: 'svg'
  scope:
    data: '='
    filters: '='
    map: '='
    duration: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    width = $element.parent().width()
    height = $scope.map.height

    svg = d3element.append 'svg'
    .classed 'bar-chart', true
    .attr 'width', width
    .attr 'height', height

    return
