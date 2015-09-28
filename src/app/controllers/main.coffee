app.controller 'mainCtrl', ($scope) ->
  $scope.monthNames = [
    ['янв', 'янв'],
    ['фев', 'фев'],
    ['мар', 'мар'],
    ['апр', 'апр'],
    ['май', 'мая'],
    ['июнь', 'июня'],
    ['июль', 'июля'],
    ['авг', 'авг'],
    ['сен', 'сен'],
    ['окт', 'окт'],
    ['ноя', 'ноя'],
    ['дек', 'дек']
  ]

  $scope.data = []

  $scope.isDataPrepared = false

  $scope.model =
    region: 'РФ'
    date: '2015 год'

  # Parse data
  parseData = (error, rawData) ->
    if error
      console.log error

    $scope.isDataPrepared = true
    $('.loading-cover').hide()

    $scope.$apply()
    return

  # Load data
  queue()
  .defer d3.csv, '../data/newbicotender_table_tender.csv'
  .awaitAll parseData

  return
