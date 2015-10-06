app.directive 'barChart', ->
  restrict: 'E'
  templateNamespace: 'svg'
  scope:
    data: '='
    filters: '='
    duration: '='
  link: ($scope, $element, $attrs) ->
    element = $element[0]
    d3element = d3.select element

    return
