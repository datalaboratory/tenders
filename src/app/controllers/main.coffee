app.controller 'mainCtrl', ($scope) ->
  dsv = d3.dsv ';', 'text/plain'

  dateFormat = 'YYYY-MM-DD'

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

  $scope.duration = 500

  $scope.tenders = []
  $scope.mapData = {}
  $scope.citiesData = []

  $scope.isDataPrepared = false

  # Parse main data
  parseMainData = (error, rawData) ->
    if error
      console.log error

    regions = {}
    fields = {}
    companies = {}
    tenderTypes = {}
    colors = {}
    codes = {}

    # Regions
    rawData[0].forEach (rD) ->
      regions[rD['region_id']] =
        root: rD['first_parent_id']
        name: rD['name']
        level: rD['nestedLevel']
        path: rD['pathToRoot']
      return

    # Fields
    rawData[1].forEach (rD) ->
      fields[rD['field_id']] =
        root: rD['first_parent_id']
        name: rD['name']
      return

    # Companies
    rawData[2].forEach (rD) ->
      companies[rD['company_id']] = if rD['shortName'] is 'NULL' then rD['name'] else rD['shortName']
      return

    # Tender types
    rawData[3].forEach (rD) ->
      tenderTypes[rD['type_id']] = rD['caption']
      return

    # Codes
    rawData[4].forEach (rD) ->
      codes[rD['name']] = rD['code']
      return

    # Colors
    rawData[5].forEach (rD) ->
      colors[rD['field']] = rD['color']
      return

    # Tenders
    rawData[6].forEach (rD) ->
      id = rD['tender_id']
      name = rD['name']
      type = tenderTypes[rD['type_id']]
      price = parseInt rD['cost']
      date = moment(rD['startDate'], dateFormat).toDate()
      customer = companies[rD['company_id']]
      field = fields[fields[rD['field_id']]['root']]['name']
      color = colors[fields[fields[rD['field_id']]['root']]['name']]
      regionObject = regions[regions[rD['region_id']]['path'].split(',')[2]]
      region = (if regionObject then regionObject['name'] else '').trim()
      code = codes[region]

      $scope.tenders.push
        id: id
        name: name
        type: type
        price: price
        date: date
        customer: customer
        field: field
        color: color
        region: region
        code: code
      return

    # Filter tenders by date
    $scope.tenders.sort (a, b) -> a.date - b.date

    startDate = moment('2014-07-31', dateFormat).toDate()
    endDate = moment('2015-08-01', dateFormat).toDate()

    $scope.tenders = $scope.tenders.filter (t) -> startDate < t.date < endDate

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
  .defer dsv, '../data/tenders/shared_table_region.csv'
  .defer dsv, '../data/tenders/shared_table_field.csv'
  .defer dsv, '../data/tenders/newbicotender_table_company.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tenderType.csv'
  .defer d3.csv, '../data/accessories/region-codes.csv'
  .defer d3.csv, '../data/accessories/field-colors.csv'
  .defer dsv, '../data/tenders/newbicotender_table_tender.csv'
  .awaitAll parseMainData

  $(window).on 'resize', ->
    $scope.$broadcast 'render'
    return

  return
