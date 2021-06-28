import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sorting_visualization/app/locator.dart';
import 'package:sorting_visualization/datamodels/algorithmType.dart';
import 'package:sorting_visualization/datamodels/dialogType.dart';
import 'package:sorting_visualization/utils/contents.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class VisualizerViewModel extends FutureViewModel<StreamController<List<int>>> {

  final _snackBarService = locator<SnackbarService>();
  final _dialogService = locator<DialogService>();
  final _navigationService = locator<NavigationService>();
  final dataContent = DataContent();

  AlgorithmType _algorithmType;
  VisualizerViewModel(this._algorithmType);

  List<int> _numbers = [];

  int _chkValueIdx = -1;
  int get checkingValueIdx => _chkValueIdx;

  int _sampleSize = 50;
  int get sampleSize => _sampleSize;

  int _maxNumber = 400;
  int get maxNumber => _maxNumber;

  double _sortingSpeed = 0.0;
  double get sortingSpeed => _sortingSpeed;

  int _sortDuration = 0;
  int get sortDuration => _sortDuration;

  bool isLoading = true;
  bool isSorting = false;
  bool isContentExpanded = false;
  bool isFirstTime = true;

  var _currentDrnIdx = 0;
  List<Duration> speeds = [
    Duration(milliseconds: 50),
    Duration(milliseconds: 30),
    Duration(milliseconds: 20),
    Duration(milliseconds: 10),
    Duration(milliseconds: 5)
  ];

  StreamController<List<int>> _streamController;

  @override
  Future<StreamController<List<int>>> futureToRun() async {
    isLoading = true;
    return new StreamController();
  }

  @override
  void onData(StreamController data) {
    super.onData(data);
    _streamController = data;
    reset();
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  StreamController getStreamController() {
    return _streamController;
  }

  reset() {
    if (isSorting) {
      _snackBarService.showSnackbar(message: "Sorting in Progress...");
      return;
    }
    _numbers = [];
    for (int i = 0; i < _sampleSize; ++i) {
      _numbers.add(Random().nextInt(_maxNumber.toInt()));
    }

    _streamController.add(_numbers);
    _sortDuration = 0;
    notifyListeners();
  }

  onActionBtn() async {
    isFirstTime = false;
    if (isArraySorted()) {
      _snackBarService.showSnackbar(message: "Array already sorted!");
      return;
    }
    if (isSorting) {
      isSorting = false;
      notifyListeners();
    } else {
      Stopwatch _stopWatch = new Stopwatch()..start();
      isSorting = true;
      notifyListeners();

      if (_algorithmType == AlgorithmType.BUBBLE_SORT) {
        await _bubbleSort();
      }
      else if (_algorithmType == AlgorithmType.MERGE_SORT)
        await _mergeSort(0, _sampleSize - 1);

      isSorting = false;
      _stopWatch.stop();
      _sortDuration = _stopWatch.elapsed.inMilliseconds;
      _chkValueIdx = -1;
      notifyListeners();
      _snackBarService.showSnackbar(message: "Completed");
    }
  }

  updateSpeed(double value) {
    if (value == 0.0) _currentDrnIdx = 0;
    if (value == 0.25) _currentDrnIdx = 1;
    if (value == 0.5) _currentDrnIdx = 2;
    if (value == 0.75) _currentDrnIdx = 3;
    if (value == 1.0) _currentDrnIdx = 4;
    _sortingSpeed = value;
    notifyListeners();
  }

  Duration _getDuration() {
    return speeds[_currentDrnIdx];
  }

  GlobalKey<ScaffoldState> _globalDrawerKey = GlobalKey();
  getGlobalKey() {
    return _globalDrawerKey;
  }
  openMenuDrawer() {
    if (isSorting) {
      _snackBarService.showSnackbar(message: "To change Algorithm Stop Sorting");
      return;
    }
    _globalDrawerKey.currentState.openEndDrawer();
  }

  expandContentSheet() {
    isContentExpanded = !isContentExpanded;
    _snackBarService.showSnackbar(message: 'Need to be done: $isContentExpanded');
    notifyListeners();
  }

  List<int> getNumbers() {
    return _numbers;
  }

  _bubbleSort() async {
    mainFlow: for (int i = 0; i < _numbers.length; ++i) {
      for (int j = 0; j < _numbers.length - i - 1; ++j) {
        if (_numbers[j] > _numbers[j + 1]) {
          int temp = _numbers[j];
          _numbers[j] = _numbers[j + 1];
          _numbers[j + 1] = temp;
        }

        if (!isSorting) break mainFlow;
        await Future.delayed(_getDuration(), () {});

        _chkValueIdx = j;
        _streamController.add(_numbers);
      }
    }
  }

  _mergeSort(int leftIndex, int rightIndex) async {
    Future<void> merge(int leftIndex, int middleIndex, int rightIndex) async {
      int leftSize = middleIndex - leftIndex + 1;
      int rightSize = rightIndex - middleIndex;

      List leftList = new List(leftSize);
      List rightList = new List(rightSize);

      for (int i = 0; i < leftSize; i++) leftList[i] = _numbers[leftIndex + i];
      for (int j = 0; j < rightSize; j++)
        rightList[j] = _numbers[middleIndex + j + 1];

      int i = 0, j = 0;
      int k = leftIndex;

      while (i < leftSize && j < rightSize) {
        if (leftList[i] <= rightList[j]) {
          _numbers[k] = leftList[i];
          i++;
        } else {
          _numbers[k] = rightList[j];
          j++;
        }

        await Future.delayed(_getDuration(), () {});
        _chkValueIdx = k;
        _streamController.add(_numbers);

        k++;
      }

      while (i < leftSize) {
        _numbers[k] = leftList[i];
        i++;
        k++;

        await Future.delayed(_getDuration(), () {});
        _streamController.add(_numbers);
      }

      while (j < rightSize) {
        _numbers[k] = rightList[j];
        j++;
        k++;

        await Future.delayed(_getDuration(), () {});
        _chkValueIdx = k;
        _streamController.add(_numbers);
      }
    }

    if (leftIndex < rightIndex) {
      int middleIndex = (rightIndex + leftIndex) ~/ 2;

      await _mergeSort(leftIndex, middleIndex);
      await _mergeSort(middleIndex + 1, rightIndex);

      await Future.delayed(_getDuration(), () {});
      _chkValueIdx = middleIndex;
      _streamController.add(_numbers);

      await merge(leftIndex, middleIndex, rightIndex);
    }
  }

  bool isArraySorted() {
    for (int i = 1; i < _numbers.length; i++) {
      if (_numbers[i - 1] > _numbers[i]) return false;
    }
    return true;
  }

  String getTitle() {
    return dataContent.getAlgorithmTitle(_algorithmType);
  }

  String getAlgorithmDesc() {
    return dataContent.getDescription(_algorithmType);
  }

  String getTC(int idx) {
    return dataContent.getTimeComplexities(_algorithmType)[idx];
  }

  String getAlgorithmCode() {
    return dataContent.getAlgorithmCode(_algorithmType);
  }

  onCustomBtnClick() async {
    var dialogResponse = await _dialogService.showCustomDialog(
      variant: DialogType.CUSTOM_INPUT,
      title: "Provide elements of the Array",
      description: "Example: 23, 45, 98, 67",
      mainButtonTitle: "Submit",
      secondaryButtonTitle: "Cancel",
      barrierDismissible: false
    );

    if (dialogResponse != null && dialogResponse.confirmed && dialogResponse.responseData.toString().isNotEmpty) {

      List<String> responseArray =
      dialogResponse.responseData.toString().split(",");
      List<int> inputArray = [];
      bool flag = true;

      responseArray.forEach((element) {
        try {
          var num = int.parse(element.trim());
          inputArray.add(num);
        } catch (e) {
          flag = false;
        }
      });

      !flag
          ? _snackBarService.showSnackbar(message: "Invalid numbers")
          : _snackBarService.showSnackbar(message: "Your Array: $inputArray");

      if (flag) {
        _numbers = inputArray;
        _sampleSize = inputArray.length;
        _maxNumber = _numbers.first;
        _numbers.forEach((num) {
          if (_maxNumber < num) {
            _maxNumber = num;
          }
        });
        // notifyListeners();
      }
    }
  }

  onBackBtnPressed() {
    _navigationService.back();
  }

  List<String> getAlgorithmsList() {
    return dataContent.getAlgorithms();
  }

  onMenuItemClick(String value) {
    _algorithmType = dataContent.getAlgorithmType(value);
    notifyListeners();
  }
}
