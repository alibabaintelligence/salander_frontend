import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:salander_frontend/classes/analysis_results.dart';
import 'package:salander_frontend/graphs/velocity_time.dart';
import 'package:salander_frontend/helpers/message_helper.dart';

void main() => runApp(const SalanderPlatform());

enum Approach {
  computationalVision,
  staLtaMaxPoints,
  statistic,
  anomalyDetection,
  kernelDensityEstimation,
}

class SalanderPlatform extends StatelessWidget {
  const SalanderPlatform({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salander Platform',
      routes: {
        '/': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Approach> approaches = [];

  String result = '';

  final List<PlatformFile> files = [];

  Future<void> _selectFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'mseed'],
    );

    if (result != null) {
      // For now we allow just one file
      files.clear();
      files.add(result.files[0]);
    } else {
      debugPrint("No file selected");
    }

    setState(() {});
  }

  bool _isAnalysisLoading = false;

  Future<Map<String, dynamic>> runSoleAnalysis(
    PlatformFile file,
    Approach approach,
  ) async {
    final approachInfo = approachesInfo.firstWhere(
      (info) => info['approach'] == approach,
    );

    const String baseUrl =
        'https://salanderbackend-e0hjhcbeeugeg4gu.canadacentral-01.azurewebsites.net';

    var apiUrl = '';
    switch (approach) {
      case Approach.computationalVision:
        apiUrl = '$baseUrl/computational-vision/';
        break;
      case Approach.staLtaMaxPoints:
        apiUrl =
            '$baseUrl/sta-lta/${approachInfo['properties']['type']['value']}';
        break;
      case Approach.statistic:
        apiUrl = '$baseUrl/statistic/';
        break;
      case Approach.anomalyDetection:
        apiUrl = '$baseUrl/anomaly-detection/';
        break;
      case Approach.kernelDensityEstimation:
        apiUrl = '$baseUrl/kernel-density/';
        break;
      default:
    }

    print("Running sole analysis under: " + apiUrl);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path!),
      );

      var response = await request.send();
      debugPrint(response.statusCode.toString());

      String responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(responseBody);

        debugPrint(
            'File processed successfully.\nFilename: ${decodedResponse['filename']}\nCFT Max: ${decodedResponse['cft_max']}\n');

        print(decodedResponse['metrics']);

        String? dataCSV = decodedResponse['data_csv'];
        String? indexesCSV = decodedResponse['indexes_csv'];

        // Save CSV files
        String? dataCSVPath =
            await _saveCSVFile(dataCSV, '${approach.name}_data.csv');
        String? indexesCSVPath =
            await _saveCSVFile(indexesCSV, '${approach.name}_indexes.csv');

        MessageHelper.showCustomSnackBar(
          context: context,
          message:
              'CSV files saved successfully: $dataCSVPath \n $indexesCSVPath',
          leading: LeadingIcons.good,
        );

        return {
          'approach': approach.name,
          'status': 'success',
          'data': decodedResponse,
          'dataCSVPath': dataCSVPath,
          'indexesCSVPath': indexesCSVPath,
        };
      } else {
        return {
          'approach': approach.name,
          'status': 'error',
          'message': 'HTTP ${response.statusCode}: $responseBody',
        };
      }
    } catch (e) {
      print('Error in runSoleAnalysis for ${approach.name}: $e');
      return {
        'approach': approach.name,
        'status': 'error',
        'message': e.toString(),
      };
    }
  }

  List<AnalysisResults> analysisResults = [];

  Future<void> runParallelAnalysis() async {
    if (files.isEmpty) {
      print("No file selected");
      return;
    }

    try {
      Map<String, dynamic> approachInfo;

      List<Future<Map<String, dynamic>>> futures = approaches.map((appr) {
        print('Running approach [${appr.name}] with file [${files[0].name}]');

        return runSoleAnalysis(files[0], appr);
      }).toList();

      List<Map<String, dynamic>> results = await Future.wait(futures);

      // Process analysis results
      for (var result in results) {
        try {
          print('Analysis result: ${result['approach']}: ${result['status']}');

          final analysisRes = parseCSVData(
            dataCSV: result['data']['data_csv'],
            indexesCSV: result['data']['indexes_csv'],
          );

          analysisResults.add(analysisRes);
        } catch (err) {
          print(err);
        }
      }
    } catch (e) {
      print('Error in parallel analysis: $e');
    }
  }

  Future<String?> _saveCSVFile(String? csvContent, String fileName) async {
    if (csvContent == null) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvContent);
      print('CSV file saved: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error saving CSV file: $e');
      return null;
    }
  }

  int selectedButtonIndex = -1; // Holds the index of the selected button

  // Example info for each button (replace with your own info)
  List<Map<String, dynamic>> approachesInfo = [
    {
      'index': 0,
      'approach': Approach.computationalVision,
      'color': Colors.redAccent,
      'title': 'Computational Vision',
      'description':
          'This approach focuses on X, Y, and Z to achieve the goal.',
      'advantages': [
        'Advantage 1 of Approach 1',
        'Advantage 2 of Approach 1',
      ],
      'disadvantages': [
        'Disadvantage 1 of Approach 1',
        'Disadvantage 2 of Approach 1',
      ],
      'bestUseCase': 'This approach is best used when condition A is met.',
      'properties': {}
    },
    {
      'index': 1,
      'approach': Approach.kernelDensityEstimation,
      'color': Colors.purpleAccent,
      'title': 'Kernel Density Estimation',
      'description':
          'This approach targets X and Y, focusing on optimizing certain aspects.',
      'advantages': [
        'Advantage 1 of Approach 3',
        'Advantage 2 of Approach 3',
      ],
      'disadvantages': [
        'Disadvantage 1 of Approach 3',
        'Disadvantage 2 of Approach 3',
      ],
      'bestUseCase': 'This is most effective when Y is the primary goal.',
      'properties': {}
    },
    {
      'index': 2,
      'approach': Approach.anomalyDetection,
      'color': Colors.pinkAccent,
      'title': 'Anomaly Detection',
      'description':
          'This approach targets X and Y, focusing on optimizing certain aspects.',
      'advantages': [
        'Advantage 1 of Approach 3',
        'Advantage 2 of Approach 3',
      ],
      'disadvantages': [
        'Disadvantage 1 of Approach 3',
        'Disadvantage 2 of Approach 3',
      ],
      'bestUseCase': 'This is most effective when Y is the primary goal.',
      'properties': {}
    },
    {
      'index': 3,
      'approach': Approach.staLtaMaxPoints,
      'color': Colors.blueAccent,
      'title': 'STA/LTA on maximum points',
      'description':
          'This approach emphasizes A, B, and C for achieving success.',
      'advantages': [
        'Advantage 1 of Approach 2',
        'Advantage 2 of Approach 2',
      ],
      'disadvantages': [
        'Disadvantage 1 of Approach 2',
        'Disadvantage 2 of Approach 2',
      ],
      'bestUseCase':
          'This approach is ideal for scenarios where B is a priority.',
      'properties': {
        'type': {
          'value': 'moon',
          'possibleValues': ['moon', 'mars']
        },
      }
    },
    {
      'index': 4,
      'approach': Approach.statistic,
      'color': Colors.greenAccent,
      'title': 'Statistical Approach',
      'description':
          'This approach targets X and Y, focusing on optimizing certain aspects.',
      'advantages': [
        'Advantage 1 of Approach 3',
        'Advantage 2 of Approach 3',
      ],
      'disadvantages': [
        'Disadvantage 1 of Approach 3',
        'Disadvantage 2 of Approach 3',
      ],
      'bestUseCase': 'This is most effective when Y is the primary goal.',
      'properties': {}
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 39, 39, 39),
      body: DefaultTextStyle(
        style: GoogleFonts.sora(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: 70.0,
              horizontal: 30.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Interplanetary Seismic Detection',
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.25,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'v0.0.1',
                              style: GoogleFonts.firaCode(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/logo.png',
                              width: 60.0,
                            ),
                            // const SizedBox(height: 10.0),
                            // const Text(
                            //   'Salander',
                            //   style: TextStyle(
                            //     fontSize: 14.0,
                            //     fontWeight: FontWeight.w500,
                            //     letterSpacing: 0.1,
                            //   ),
                            // ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 25.0),
                    // Step 1
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text(
                        '1. Upload data file to be tested (.csv/.mseed formats only)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CupertinoButton(
                              onPressed: _selectFile,
                              borderRadius: BorderRadius.circular(15.0),
                              padding: EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 30.0,
                              ),
                              color: Color.fromARGB(255, 21, 21, 21),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.upload_file_rounded,
                                    size: 19.0,
                                    color: Color.fromARGB(255, 255, 225, 106),
                                  ),
                                  SizedBox(width: 14.0),
                                  Text(
                                    'Upload File',
                                    style: GoogleFonts.sora(
                                      color: Color.fromARGB(255, 255, 225, 106),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...files.map(
                              (file) => Container(
                                margin: const EdgeInsets.only(top: 5.0),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 21, 21, 21),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 25.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CupertinoButton(
                                      onPressed: () {
                                        setState(() {
                                          files.remove(file);
                                        });
                                      },
                                      minSize: 0.0,
                                      padding: EdgeInsets.zero,
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 16.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10.0),
                                    Text(
                                      file.name,
                                      style: GoogleFonts.firaCode(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Step 2
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        children: [
                          Text(
                            '2. Select analysis approach.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                    ),
                    // Cupertino Buttons
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...approachesInfo.map(
                            (buttonInfo) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CupertinoButton(
                                  color: Color.fromARGB(255, 21, 21, 21),
                                  borderRadius: BorderRadius.circular(15.0),
                                  padding: EdgeInsets.symmetric(
                                    vertical: 4.0,
                                    horizontal: 30.0,
                                  ),
                                  child: Text(
                                    buttonInfo['title'],
                                    style: GoogleFonts.sora(
                                      color: buttonInfo['color'],
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      selectedButtonIndex = buttonInfo['index'];
                                    });
                                  },
                                ),
                                const SizedBox(width: 10.0),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Info based on selected button
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 25.0,
                      ),
                      child: selectedButtonIndex == -1
                          ? Container() // Empty container if no button is pressed
                          : buildInfoColumn(
                              approachesInfo[selectedButtonIndex],
                            ),
                    ),
                    SizedBox(height: 20.0),
                    // Step 3
                    Text(
                      '3. Run and test approach.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...approaches.map(
                            (approach) {
                              final approachInfo = approachesInfo.firstWhere(
                                (info) => info['approach'] == approach,
                              );

                              return Container(
                                margin: const EdgeInsets.only(top: 5.0),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 21, 21, 21),
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10.0,
                                  horizontal: 15.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CupertinoButton(
                                      onPressed: () {
                                        approaches.remove(approach);
                                        setState(() {});
                                      },
                                      minSize: 0.0,
                                      padding: EdgeInsets.zero,
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 16.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 5.0),
                                    Text(
                                      approachInfo['title'],
                                      style: GoogleFonts.sora(
                                        color: approachInfo['color'],
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CupertinoButton(
                              onPressed: _isAnalysisLoading
                                  ? null
                                  : () async {
                                      if (!_isAnalysisLoading) {
                                        setState(() {
                                          _isAnalysisLoading = true;
                                        });

                                        try {
                                          // await Future.wait([
                                          //   ...approaches.map(
                                          //     (appr) {
                                          //       print('running approach [' +
                                          //           appr.name +
                                          //           "] with file [" +
                                          //           files[0].name +
                                          //           "]");

                                          //       return runSoleAnalysis(
                                          //         files[0],
                                          //         appr,
                                          //       );
                                          //     },
                                          //   )
                                          // ]);

                                          print('Starting parallel analysis');

                                          await runParallelAnalysis();
                                        } catch (err) {
                                          print(err);
                                        } finally {
                                          setState(() {
                                            _isAnalysisLoading = false;
                                          });
                                        }
                                      }
                                    },
                              borderRadius: BorderRadius.circular(15.0),
                              padding: EdgeInsets.symmetric(
                                vertical: 4.0,
                                horizontal: 30.0,
                              ),
                              color: _isAnalysisLoading
                                  ? const Color.fromARGB(255, 32, 32, 32)
                                  : const Color.fromARGB(255, 21, 21, 21),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 19.0,
                                    color: _isAnalysisLoading
                                        ? Colors.grey
                                        : Color.fromARGB(255, 255, 225, 106),
                                  ),
                                  SizedBox(width: 14.0),
                                  Text(
                                    'Run Analysis',
                                    style: GoogleFonts.sora(
                                      color: _isAnalysisLoading
                                          ? Colors.grey
                                          : Color.fromARGB(255, 255, 225, 106),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isAnalysisLoading)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 25.0),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CupertinoActivityIndicator(
                                        color: Colors.grey,
                                        radius: 15.0,
                                      ),
                                      SizedBox(width: 18.0),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Analysis running...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15.0,
                                            ),
                                          ),
                                          SizedBox(height: 5.0),
                                          Text(
                                            'Please be patient, depending on the amount of data\nand type of analysis, this might take a while.',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w300,
                                              fontSize: 11.0,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            SizedBox(height: 30.0),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...analysisResults.map(
                      (res) => VelocityTimeGraph(
                        analysisResults: res,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Function to dynamically build the info column from the map
  Widget buildInfoColumn(Map<String, dynamic> approachInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              approachInfo['title'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: approachInfo['color'],
              ),
            ),
            const SizedBox(width: 15.0),
            CupertinoButton(
              onPressed: !approaches.contains(approachInfo['approach'])
                  ? () async {
                      if (!approaches.contains(approachInfo['approach'])) {
                        Map<String, dynamic>? propertiesData;

                        if ((approachInfo['properties'] as Map).isNotEmpty) {
                          await showDialog<Map<String, dynamic>?>(
                            context: context,
                            builder: (BuildContext context) {
                              return ApproachInfoPopup(
                                properties: approachInfo['properties'],
                                onSave: (resultantFormData) {
                                  print(
                                    'Saved data: $resultantFormData',
                                  );

                                  propertiesData = resultantFormData;
                                },
                              );
                            },
                          );

                          print(propertiesData);

                          if (propertiesData == null) return;

                          approachesInfo[approachesInfo.indexOf(approachInfo)]
                              ['properties'] = propertiesData;
                        }

                        setState(() {
                          approaches.add(approachInfo['approach']);
                        });
                      }
                    }
                  : () {
                      setState(() {
                        approaches.remove(approachInfo['approach']);
                      });
                    },
              borderRadius: BorderRadius.circular(10.0),
              padding: EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 12.0,
              ),
              minSize: 0.0,
              color: !approaches.contains(approachInfo['approach'])
                  ? const Color.fromARGB(255, 21, 21, 21)
                  : const Color.fromARGB(255, 32, 32, 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_rounded,
                    size: 19.0,
                    color: !approaches.contains(approachInfo['approach'])
                        ? Colors.white
                        : Colors.grey,
                  ),
                  const SizedBox(width: 5.0),
                  Text(
                    'Select',
                    style: GoogleFonts.sora(
                      color: !approaches.contains(approachInfo['approach'])
                          ? Colors.white
                          : Colors.grey,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12.0),
        // Description
        Text(
          approachInfo['description'],
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13.5,
          ),
        ),
        SizedBox(height: 20.0),
        // Advantages
        Text(
          'Advantages:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 5.0),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(approachInfo['advantages'].length,
                (index) {
              return Text(
                '•  ${approachInfo['advantages'][index]}',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 13.5,
                ),
              );
            }),
          ),
        ),
        SizedBox(height: 10.0),
        // Disadvantages
        Text(
          'Disadvantages:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 5.0),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List<Widget>.generate(
              approachInfo['disadvantages'].length,
              (index) {
                return Text(
                  '•  ${approachInfo['disadvantages'][index]}',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 13.5,
                  ),
                );
              },
            ),
          ),
        ),
        SizedBox(height: 15.0),
        // Best Use Case
        Text(
          'Best Use Case:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 5.0),
        Text(
          approachInfo['bestUseCase'],
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class ApproachInfoPopup extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;
  final Map<String, dynamic> properties;

  const ApproachInfoPopup({
    super.key,
    required this.onSave,
    required this.properties,
  });

  @override
  State<ApproachInfoPopup> createState() => _ApproachInfoPopupState();
}

class _ApproachInfoPopupState extends State<ApproachInfoPopup> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _propertiesFormData;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    _propertiesFormData = {};
    widget.properties.forEach((key, propMap) {
      if (propMap is Map<String, dynamic>) {
        _propertiesFormData[key] = propMap['value'];
      }
    });
  }

  Widget _buildFormField(String propertyName, dynamic propertyValue) {
    if (propertyValue is Map<String, dynamic>) {
      if (propertyValue.containsKey('possibleValues')) {
        // Dropdown for string properties with possible values
        return DropdownButtonFormField<String>(
          value: _propertiesFormData[propertyName],
          items: (propertyValue['possibleValues'] as List).map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _propertiesFormData[propertyName] = newValue;
            });
          },
          decoration: InputDecoration(labelText: propertyName),
        );
      } else {
        return TextFormField(
          initialValue: _propertiesFormData[propertyName].toString(),
          decoration: InputDecoration(labelText: propertyName),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _propertiesFormData[propertyName] =
                int.tryParse(value) ?? _propertiesFormData[propertyName];
          },
        );
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Approach Info'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.properties.entries.map(
              (entry) {
                return _buildFormField(entry.key, entry.value);
              },
            ).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                {
                  ...widget.properties.map(
                    (propertyName, oldValue) => MapEntry(
                      propertyName,
                      {
                        'possibleValues': oldValue['possibleValues'],
                        'value': _propertiesFormData[propertyName],
                      },
                    ),
                  ),
                },
              );
              Navigator.of(context).pop();
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
