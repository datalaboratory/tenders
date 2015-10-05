app.directive 'legend', ->
  restrict: 'E'
  templateUrl: 'templates/directives/legend.html'
  scope:
    fieldColors: '='
    legend: '='
  link: ($scope, $element, $attrs) ->
    return
