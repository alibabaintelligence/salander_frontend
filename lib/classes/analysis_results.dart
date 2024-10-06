class DetectionWindow {
  final double start;
  final double end;
  final double? percentage;
  DetectionWindow(
      {required this.start, required this.end, required this.percentage});
}

class VelocityPlot {
  final double velocity;
  final double time;
  VelocityPlot({required this.velocity, required this.time});
}

class AnalysisResults {
  List<VelocityPlot> velocityPlots;
  List<DetectionWindow> detectionWindows;

  AnalysisResults({
    required this.velocityPlots,
    required this.detectionWindows,
  });
}

AnalysisResults parseCSVData({
  required String dataCSV,
  required String indexesCSV,
}) {
  print("CSV DATA TO PARSE LOLLLLLLL");

  List<VelocityPlot> velocityPlots = [];
  List<DetectionWindow> detectionWindows = [];

  // Parse data CSV
  List<String> dataLines = dataCSV.split('\n');
  for (int i = 1; i < dataLines.length; i++) {
    List<String> values = dataLines[i].split(',');
    if (values.length >= 3) {
      try {
        double time = double.parse(values[1]);
        double velocity = double.parse(values[2]);
        velocityPlots.add(VelocityPlot(time: time, velocity: velocity));
      } catch (e) {
        print("Error parsing line $i of data CSV: $e");
      }
    }
  }

  List<String> indexLines = indexesCSV.split('\n');
  for (int i = 1; i < indexLines.length; i++) {
    List<String> values = indexLines[i].split(',');
    if (values.length >= 3) {
      try {
        double start = double.parse(values[0]);
        double end = double.parse(values[1]);
        double percentage = double.parse(values[2]);
        detectionWindows.add(
            DetectionWindow(start: start, end: end, percentage: percentage));
      } catch (e) {
        print("Error parsing line $i of index CSV: $e");
      }
    }
  }

  print("Velocity plots count: ${velocityPlots.length}");
  print("Detection windows count: ${detectionWindows.length}");

  return AnalysisResults(
    velocityPlots: velocityPlots,
    detectionWindows: detectionWindows,
  );
}
