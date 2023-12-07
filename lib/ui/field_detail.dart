import 'package:direction/ui/irrigation_history.dart';
import 'package:direction/ui/predict_disease.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../model/field.dart';
import 'customized_parameters_page.dart';
import 'detail_irrigation.dart';
import '../styles.dart';
import 'package:direction/ui/predicted_yield_page.dart';

class FieldDetail extends StatefulWidget {
  final Field field;

  FieldDetail(this.field);

  @override
  createState() => _FieldDetailState(this.field);
}

class _FieldDetailState extends State<FieldDetail> {
  final Field _field;
  bool loading = false;

  _FieldDetailState(this._field);

  @override
  void initState() {
    //this.field.runModel();
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(this._field.fieldName),
        ),
        body: _refreshBody(context, _field));
  }

  Widget _refreshBody(BuildContext context, Field field) {
    return RefreshIndicator(
        child: _loadDataBeforeRenderBody(context, field),
        onRefresh: _pullFresh);
  }

  Future<void> _pullFresh() async {
    setState(() {
      _loadData();
    });
  }

  Widget _loadDataBeforeRenderBody(BuildContext context, Field field) {
    return FutureBuilder(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${snapshot.error} occurred',
              style: TextStyle(fontSize: 18),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          return _renderBody(context, field);
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  _loadData() async {
    await this._field.runModel();
  }

  Widget _renderBody(BuildContext context, Field field) {
    var result = <Widget>[];
    result.add(_renderPredictYield());
    result.add(_renderIrrigation());
    result.add(_renderIrrigationHistory());
    result.add(_renderEditField());
    result.add(_renderDisease());
    result.add(_renderDownloadWeatherData());
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: result,
      ),
    );
  }

  Widget _renderDisease() {
    return Container(
        padding: EdgeInsets.only(left: 15, top: 10, right: 15, bottom: 15),
        child: SizedBox(
          height: 70,
          child: ElevatedButton(
            style: Styles.fieldDetailButtonStyle,
            child: Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                      'Disease prediction',
                      style: Styles.fieldDetailTextStyle),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Styles.iconColor,
                  ),
                ),
              ],
            ),
            onPressed: () =>
                _navigateToDiseasePredictPage(context, this._field),
          ),
        ));
  }

  Widget _renderDownloadWeatherData() {
    return Container(
        padding: EdgeInsets.only(left: 15, top: 10, right: 15, bottom: 15),
        child: SizedBox(
          height: 70,
          child: ElevatedButton(
            style: Styles.fieldDetailButtonStyle,
            child: Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                      AppLocalizations.of(context)!.downloadWeatherDataFile,
                      style: Styles.fieldDetailTextStyle),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.download,
                    color: Styles.iconColor,
                  ),
                ),
              ],
            ),
            onPressed: () => this._field.downloadWeatherDataFile(),
          ),
        ));
  }

  Widget _renderEditField() {
    return Container(
        padding: EdgeInsets.only(left: 15, top: 10, right: 15, bottom: 15),
        child: SizedBox(
          height: 70,
          child: ElevatedButton(
            style: Styles.fieldDetailButtonStyle,
            child: Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                      AppLocalizations.of(context)!
                          .editFieldName(this._field.fieldName),
                      style: Styles.fieldDetailTextStyle),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Styles.iconColor,
                  ),
                ),
              ],
            ),
            onPressed: () =>
                _navigateToCustomizedParametersPage(context, this._field),
          ),
        ));
  }

  Future<void> _navigateToCustomizedParametersPage(
      BuildContext context, Field field) async {
    // await field.customizedParameters.getDataFromDb();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CustomizedParametersPage(this._field)));
  }

  void _navigateToDiseasePredictPage(BuildContext context, Field field) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => PredictDisease(field)));
  }

  void _navigateToPredictedYieldPage(BuildContext context, Field field) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => PredictedYieldPage(field)));
  }

  Widget _renderPredictYield() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SizedBox(
          height: 70,
          child: ElevatedButton(
            style: Styles.fieldDetailButtonStyle,
            child: Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                      AppLocalizations.of(context)!
                          .predictTheYieldOfField(this._field.fieldName),
                      style: Styles.fieldDetailTextStyle),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Styles.iconColor,
                  ),
                ),
              ],
            ),
            onPressed: () => _navigateToPredictedYieldPage(
                context, this._field), // todo show the predicted yield
          )),
    );
    //height: 100,
  }

  Widget _renderIrrigation() {
    return Container(
        padding: EdgeInsets.only(left: 15, top: 10, right: 15, bottom: 15),
        child: SizedBox(
          height: 70,
          child: ElevatedButton(
            style: Styles.fieldDetailButtonStyle,
            child: Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 10),
                  child: Text(
                      AppLocalizations.of(context)!.monitoringIrrigation,
                      style: Styles.fieldDetailTextStyle),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Styles.iconColor,
                  ),
                ),
              ],
            ),
            onPressed: () =>
                _navigateToDetailIrrigationPage(context, this._field),
          ),
        ));
  }

  void _navigateToDetailIrrigationPage(BuildContext context, Field field) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => DetailIrrigation(field)));
  }

  Widget _renderIrrigationHistory() {
    return Container(
        padding: EdgeInsets.only(left: 15, top: 10, right: 15, bottom: 15),
        child: SizedBox(
          height: 70,
          child: ElevatedButton(
            style: Styles.fieldDetailButtonStyle,
            child: Stack(
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 10),
                  child: Text("${AppLocalizations.of(context)!.irrigationHistory}",
                      style: Styles.fieldDetailTextStyle),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Styles.iconColor,
                  ),
                ),
              ],
            ),
            onPressed: () =>
                _navigateToIrrigationHistoryPage(context, this._field.fieldName),
          ),
        ));
  }
  void _navigateToIrrigationHistoryPage (BuildContext context, String fieldName) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => IrrigationHistory(fieldName)));
  }

}
