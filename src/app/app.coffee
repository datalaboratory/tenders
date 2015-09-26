appDependencies = [
  'ngRoute'
]

app = angular.module 'app', appDependencies
.config [
  '$routeProvider', '$locationProvider'
  ($routeProvider, $locationProvider) ->
    $routeProvider
    .when '/',
      templateUrl: ''
      controller: ''
    .otherwise redirectTo: '/'
    return
]
