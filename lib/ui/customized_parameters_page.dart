import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../model/field.dart';
import 'detail_irrigation.dart';
import '../styles.dart';

const double _sliderHeight = 175;

class CustomizedParametersPage extends StatefulWidget {
  final Field field;

  CustomizedParametersPage(this.field);

  @override
  createState() => _CustomizedParametersPageState(this.field);
}

class _CustomizedParametersPageState extends State<CustomizedParametersPage> {
  final Field field;
  bool _displayConfirmButton = true;

  _CustomizedParametersPageState(this.field);

  @override
  void initState() {
    super.initState();
  }

  // void _displayTimePicker() {
  //   setState(() {
  //     _displayConfirmButton = true;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${AppLocalizations.of(context)!.edit} ${this.field.customizedParameters.fieldName}'),
      ),
      body: Stack(
        children: [
          _renderParameters(),
          if (_displayConfirmButton) _renderConfirmButton(),
        ],
      ),
    );
  }

  Widget _renderParameters() {
    List<Widget> result = [];
    result.add(_renderAcreageTextField());
    result.add(_renderIrrigationDurationSlider());
    result.add(_renderDripRateSlider());
    result.add(_renderNumberOfHoleTextField());
    result.add(_renderDistanceBetweenHolesSlider());
    result.add(_renderDistanceBetweenRowsSlider());
    result.add(_renderFieldCapacitySlider());
    //result.add(_renderScaleRainSlider());
    result.add(_renderFertilizerLevelSlider());
    result.add(_renderAutoIrrigationSwitch());
    return Container(
      width: 400,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: result,
        ),
      ),
    );
  }

  Widget _renderAcreageTextField() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            //alignment: Alignment.topLeft,
            child: Text(
              '${AppLocalizations.of(context)!.acreage}: ${this.field.customizedParameters.acreage} (m2)',
              style: Styles.locationTileTitleLight,
            ),
          ),
          SizedBox(
            width: 350,
            height: 70,
            child: TextField(
              onSubmitted: (text) {
                this.field.customizedParameters.acreage = double.parse(text);
              },
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter(RegExp(r'[0-9.]'), allow: true)
              ],
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(
                        color: Colors.blue.withOpacity(0.3), width: 2.0)),
                //labelText: '${this.field.fieldName}',
                hintText: AppLocalizations.of(context)!.enterAcreage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderNumberOfHoleTextField() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              '${AppLocalizations.of(context)!.holesNumber}: ${this.field.customizedParameters.numberOfHoles} (${AppLocalizations.of(context)!.holes})',
              style: Styles.locationTileTitleLight,
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(
            width: 350,
            height: 70,
            child: TextField(
              onSubmitted: (text) {
                this.field.customizedParameters.numberOfHoles = int.parse(text);
              },
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter(RegExp(r'[0-9]'), allow: true)
              ],
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide(
                        color: Colors.blue.withOpacity(0.3), width: 2.0)),
                //labelText: '${this.field.fieldName}',
                hintText: AppLocalizations.of(context)!.enterDripHoles,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderAutoIrrigationSwitch() {
    return Container(
      margin: EdgeInsets.only(bottom: 30),
      alignment: Alignment.center,
      height: 150,
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                child: Text(
                  '${AppLocalizations.of(context)!.autoIrrigation}',
                  style: Styles.locationTileTitleLight,
                ),
                padding: EdgeInsets.only(left: 23),
              ),
              Container(
                child: Switch(
                  value: this.field.customizedParameters.autoIrrigation,
                  onChanged: (bool value) {
                    setState(() {
                      this.field.customizedParameters.autoIrrigation = value;
                    });
                  },
                  activeColor: Styles.iconColor,
                ),
                alignment: Alignment.center,
                //padding: EdgeInsets.only(left: 100),
              ),
            ],
          ),
          Container(
            child: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: TextButton(
                    child: Text(
                        '${AppLocalizations.of(context)!.goToDetailIrrigation}'),
                    onPressed: () =>
                        _navigateToDetailIrrigationPage(context, this.field),
                  ),
                )
              ],
            ),
            alignment: Alignment.centerRight,
          )
        ],
      ),
    );
  }

  Widget _renderFieldCapacitySlider() {
    return Container(
      child: Column(
        children: [
          Container(
            child: Text(
              '${AppLocalizations.of(context)!.fieldCapacityToMaintain}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Container(
            child: Text(
              '${this.field.customizedParameters.fieldCapacity}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Slider(
              value: this.field.customizedParameters.fieldCapacity,
              onChanged: (double value) {
                setState(() {
                  this.field.customizedParameters.fieldCapacity = value;
                });
              },
              min: 0,
              max: 100,
              divisions: 100,
              label:
                  '${AppLocalizations.of(context)!.fieldCapacityToMaintain}'),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      height: _sliderHeight,
      padding: EdgeInsets.only(bottom: 20, top: 10),
    );
  }

  Widget _renderIrrigationDurationSlider() {
    return Container(
      child: Column(
        children: [
          Container(
            child: Text(
              '${AppLocalizations.of(context)!.durationOfIrrigation}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Container(
            child: Text(
              '${this.field.customizedParameters.irrigationDuration}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Slider(
              value: this.field.customizedParameters.irrigationDuration,
              onChanged: (double value) {
                setState(() {
                  this.field.customizedParameters.irrigationDuration = value;
                });
              },
              min: 0,
              max: 24,
              divisions: 100,
              label: '${AppLocalizations.of(context)!.durationOfIrrigation}'),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      height: _sliderHeight,
      padding: EdgeInsets.only(bottom: 20, top: 10),
    );
  }

  Widget _renderDripRateSlider() {
    return Container(
      child: Column(
        children: [
          Container(
            child: Text(
              '${AppLocalizations.of(context)!.dripRate}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Container(
            child: Text(
              '${this.field.customizedParameters.dripRate}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Slider(
              value: this.field.customizedParameters.dripRate,
              onChanged: (double value) {
                setState(() {
                  this.field.customizedParameters.dripRate = value;
                });
              },
              min: 0,
              max: 8,
              divisions: 100,
              label: '${AppLocalizations.of(context)!.dripRate}'),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      height: _sliderHeight,
      padding: EdgeInsets.only(bottom: 20, top: 10),
    );
  }

  Widget _renderDistanceBetweenHolesSlider() {
    return Container(
      child: Column(
        children: [
          Container(
            child: Text(
              '${AppLocalizations.of(context)!.distanceBetweenHoles}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Container(
            child: Text(
              '${this.field.customizedParameters.distanceBetweenHoles}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Slider(
              value: this.field.customizedParameters.distanceBetweenHoles,
              onChanged: (double value) {
                setState(() {
                  this.field.customizedParameters.distanceBetweenHoles = value;
                });
              },
              min: 0,
              max: 100,
              divisions: 100,
              label: '${AppLocalizations.of(context)!.distanceBetweenHoles}'),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      height: _sliderHeight,
      padding: EdgeInsets.only(bottom: 20, top: 10),
    );
  }

  Widget _renderDistanceBetweenRowsSlider() {
    return Container(
      child: Column(
        children: [
          Container(
            child: Text(
              '${AppLocalizations.of(context)!.distanceBetweenRows}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Container(
            child: Text(
              '${this.field.customizedParameters.distanceBetweenRows}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Slider(
              value: this.field.customizedParameters.distanceBetweenRows,
              onChanged: (double value) {
                setState(() {
                  this.field.customizedParameters.distanceBetweenRows = value;
                });
              },
              min: 0,
              max: 100,
              divisions: 100,
              label: '${AppLocalizations.of(context)!.distanceBetweenRows}'),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      height: _sliderHeight,
      padding: EdgeInsets.only(bottom: 20, top: 10),
    );
  }

  // Widget _renderScaleRainSlider() {
  //   return Container(
  //     child: Column(
  //       children: [
  //         Container(
  //           child: Text(
  //             '${AppLocalizations.of(context)!.scaleRain}',
  //             style: Styles.locationTileTitleLight,
  //           ),
  //           padding: EdgeInsets.only(left: 23),
  //         ),
  //         Container(
  //           child: Text(
  //             '${this.field.customizedParameters.scaleRain}',
  //             style: Styles.locationTileTitleLight,
  //           ),
  //           padding: EdgeInsets.only(left: 23),
  //         ),
  //         Slider(
  //             value: this.field.customizedParameters.scaleRain,
  //             onChanged: (double value) {
  //               setState(() {
  //                 this.field.customizedParameters.scaleRain = value;
  //               });
  //             },
  //             min: 0,
  //             max: 100,
  //             divisions: 100,
  //             label: '${AppLocalizations.of(context)!.scaleRain}'),
  //       ],
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //     ),
  //     height: _sliderHeight,
  //     padding: EdgeInsets.only(bottom: 20, top: 10),
  //   );
  // }

  Widget _renderFertilizerLevelSlider() {
    return Container(
      child: Column(
        children: [
          Container(
            child: Text(
              '${AppLocalizations.of(context)!.scaleFertilizer}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Container(
            child: Text(
              '${this.field.customizedParameters.fertilizationLevel}',
              style: Styles.locationTileTitleLight,
            ),
            padding: EdgeInsets.only(left: 23),
          ),
          Slider(
              value: this.field.customizedParameters.fertilizationLevel,
              onChanged: (double value) {
                setState(() {
                  this.field.customizedParameters.fertilizationLevel = value;
                });
              },
              min: 0,
              max: 100,
              divisions: 100,
              label: '${AppLocalizations.of(context)!.scaleFertilizer}'),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      height: _sliderHeight,
      padding: EdgeInsets.only(bottom: 20, top: 10),
    );
  }

  void _navigateToDetailIrrigationPage(BuildContext context, Field field) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => DetailIrrigation(field)));
  }

  Widget _renderConfirmButton() {
    return Container(
      child: Stack(
        children: [
          ElevatedButton(
            child: Text('${AppLocalizations.of(context)!.change}'),
            onPressed: () => {
              setState(() {
                this.field.customizedParameters.updateDataToDb();
              })
            },
          ),
        ],
      ),
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.only(bottom: 20),
    );
  }
}
