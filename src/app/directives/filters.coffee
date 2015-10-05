app.directive 'filters', ->
  restrict: 'E'
  templateUrl: 'templates/directives/filters.html'
  scope:
    filters: '='
  link: ($scope, $element, $attrs) ->
    $scope.resetFilters = ->
      $scope.filters.field = 0
      $scope.filters.price = 0
      $scope.filters.region = 0
      return

    return
