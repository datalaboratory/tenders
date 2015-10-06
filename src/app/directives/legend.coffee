app.directive 'legend', ->
  restrict: 'E'
  templateUrl: 'templates/directives/legend.html'
  scope:
    data: '='
    map: '='
    legend: '='
  link: ($scope, $element, $attrs) ->
    $scope.nOfItems = 24
    $scope.nOfItemsInColumn = 6
    $scope.nOfColumns = $scope.nOfItems / $scope.nOfItemsInColumn

    $scope.range = (n) -> new Array n

    return
