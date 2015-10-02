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

  $scope.fieldColors = [
    '#9cd994',
    '#ecb1d1',
    '#e7ab74',
    '#a8ecf2',
    '#ded374',
    '#d7beb1',
    '#c5c5f1',
    '#bdeeca',
    '#f1e3a7',
    '#f0a8a1',
    '#e7ebdf',
    '#7de0b8',
    '#bdc69d',
    '#8ec2d7',
    '#d5ed88',
    '#d5c3d6',
    '#ddbd93',
    '#aecfc6',
    '#b8be74',
    '#92c6a5',
    '#7cddd5',
    '#d0f0ab',
    '#e4bd6a',
    '#c0d5eb'
  ]

  $scope.mapData = {}
  $scope.citiesData = []

  $scope.model =
    region: 'Все регионы'
    month: ''

  $scope.isDataPrepared = false

  tenderStatuses = {}
  tenderTypes = {}

  # Parse main data
  parseMainData = (error, rawData) ->
    if error
      console.log error

    # Tender statuses
    rawData[10].forEach (d) ->
      tenderStatuses[d.status_id] =
        caption: d.caption
        name: d.name
      return

    # Tender types
    rawData[11].forEach (d) ->
      tenderTypes[d.type_id] =
        caption: d.caption
        name: d.name
        plural: d.plural
      return

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
  .defer dsv, '../data/tenders/newbicotender_table_company.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tenderCompetitor.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tender.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tenderLot.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tenderPosition.csv'
  .defer dsv, '../data/tenders/shared_table_region.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tender_appliesIn_region.csv'
  .defer dsv, '../data/tenders/shared_table_field.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tender_in_field.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tenderDuplicate.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tenderStatus.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tenderType.csv'
  .awaitAll parseMainData

  return
