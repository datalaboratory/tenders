app.controller 'mainCtrl', ($scope) ->
  dsv = d3.dsv ';', 'text/plain'

  $scope.monthNames = [
    ['январь', 'янв'],
    ['февраль', 'фев'],
    ['март', 'мар'],
    ['апрель', 'апр'],
    ['май', 'май'],
    ['июнь', 'июнь'],
    ['июль', 'июль'],
    ['август', 'авг'],
    ['сентябрь', 'сен'],
    ['октябрь', 'окт'],
    ['ноябрь', 'ноя'],
    ['декабрь', 'дек']
  ]

  $scope.mapData = {}
  $scope.citiesData = []

  $scope.model =
    region: 'Все регионы'
    month: ''

  $scope.isDataPrepared = false

  # Parse main data
  parseMainData = (error, rawData) ->
    if error
      console.log error

    # Load map data
    queue()
    .defer d3.json, '../data/map/russia.json'
    .defer d3.tsv, '../data/map/cities.tsv'
    .awaitAll parseMapData
    return

  # Parse map data
  parseMapData = (error, rawData) ->
    if error
      console.log error

    $scope.mapData = rawData[0]
    $scope.citiesData = rawData[1]

    $scope.isDataPrepared = true
    $('.loading-cover').fadeOut()

    $scope.$apply()
    return

  # Load main data
  queue()
  .defer dsv, '../data/tenders/newbicotender_table_tender.csv'
  .awaitAll parseMainData

  return
