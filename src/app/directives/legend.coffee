app.directive 'legend', ->
  restrict: 'E'
  templateUrl: 'templates/directives/legend.html'
  scope:
    fieldColors: '='
  link: ($scope, $element, $attrs) ->
    return
