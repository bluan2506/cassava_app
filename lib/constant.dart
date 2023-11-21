class Constant {
  static const USER = 'user';
  static const TEST_USER = 'testUser';
  static const CUSTOMIZED_PARAMETERS = 'customized_parameters';
  static const POTENTIAL_YIELD = 'potentialYield';
  static const POTENTIAL_YIELD_DISPLAY = 'Potential Yield';
  static const ILA = 'iLA';
  static const ILA_DISPLAY = 'Initial leaf area';
  static const RGR = 'rgr';
  static const RGR_DISPLAY = 'Relative growth rate';
  static const AUTO_IRRIGATION = 'autoIrrigation';
  static const AUT0_IRRIGATION_DISPLAY = 'Auto irrigation';
  static const MEASURED_DATA = 'measured_data';
  static const RAIN_FALL = 'rainFall';
  static const RELATIVE_HUMIDITY = 'relativeHumidity';
  static const TEMPERATURE = 'temperature';
  static const SOIL_TEMPERATURE = 'soilTemperature';
  static const WIND_SPEED = 'windSpeed';
  static const RADIATION = 'radiation';
  static const IRRIGATION_CHECK = 'irrigationCheck';
  static const START_IRRIGATION = 'startIrrigation';
  static const END_IRRIGATION = 'endIrrigation';
  static const START_TIME = 'startTime';
  static const FIELD_CAPACITY = 'fieldCapacity';
  static const FIELD_CAPACITY_DISPLAY = 'Field capacity to maintain (%)';
  static const latitude = 21.0075; // vi do
  static const longitude = 105.5416; // kinh do
  static const elevation = 16; // do cao so voi muc nuoc bien
  static const height = 2.5; // do cao
  static const nSoilLayer = 5;
  static const ACREAGE = 'acreage';
  static const IRRIGATION_DURATION = 'irrigationDuration';
  static const IRRIGATION_DURATION_DISPLAY = 'Duration of irrigation (hour)';
  static const DRIP_RATE = 'dripRate';
  static const DRIP_RATE_DISPLAY = 'Drip rate of single hole (l/h/hole)';
  static const NUMBER_OF_HOLES = 'numberOfHoles';
  static const NUMBER_OF_HOLES_DISPLAY = 'The number of drip holes';
  static const DISTANCE_BETWEEN_HOLES = 'distanceBetweenHole';
  static const DISTANCE_BETWEEN_HOLES_DISPLAY = 'Distance between holes (cm)';
  static const DISTANCE_BETWEEN_ROWS = 'distanceBetweenRow';
  static const DISTANCE_BETWEEN_ROWS_DISPLAY = 'Distance between rows (cm)';
  static const SCALE_RAIN = 'scaleRain';
  static const SCALE_RAIN_DISPLAY = 'Reduce or increase expected rainfall (%)';
  static const FERTILIZATION_LEVEL = 'fertilizationLevel';
  static const FERTILIZATION_LEVEL_DISPLAY = 'Reduce or increase fertilizer level (%)';
  static const IRRIGATION_FOR_THE_NEXT_DAY = 'irrigationForTheNextDay';
  static const IRRIGATION_INFORMATION = 'irrigation_information';
  static const AMOUNT_OF_IRRIGATION = 'amount';
  static const SOIL_HUMIDITY = 'humidity_hour';
  static const IRRIGATION_HISTORY = 'irrigation_history';
  static String format(int n) {
    if (n < 10)
      return '0$n';
    else
      return '$n';
  }

}
