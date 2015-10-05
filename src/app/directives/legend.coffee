app.directive 'legend', ->
  restrict: 'E'
  templateUrl: 'templates/directives/legend.html'
  scope:
    fieldColors: '='
    map: '='
    legend: '='
  link: ($scope, $element, $attrs) ->
    return
