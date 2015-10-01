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
