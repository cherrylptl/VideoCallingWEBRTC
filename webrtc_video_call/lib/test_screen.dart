import 'package:app_usage/app_usage.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  List? apps = [];
  List<AppUsageInfo>? infos = [];

  Future<void> getApp() async {
    try {
      apps = await DeviceApps.getInstalledApplications(
        onlyAppsWithLaunchIntent: false,
        includeAppIcons: true,
        includeSystemApps: false,
      );
      setState(() {});
    } catch (error) {
      debugPrint("Error Getting Apps: $error");
    }
  }

  void getUsageStats() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(
        const Duration(hours: 1),
      );
      List<AppUsageInfo> infoList = await AppUsage().getAppUsage(
        startDate,
        endDate,
      );

      setState(() {
        infos = infoList;
      });
    } on AppUsageException catch (exception) {
      debugPrint("AppUsageException: $exception");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Testing Screen"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: apps!.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    debugPrint("###########################################");
                    debugPrint(
                      "App Data >>>>>> ${apps![index]}",
                    );
                    debugPrint("App Name >>>>>> ${apps![index].appName}");
                    debugPrint("packageName >>>>>>>>> ${apps![index].packageName}");
                    debugPrint("###########################################");
                  },
                  child: ListTile(
                    title: Text(
                      apps![index].appName,
                    ),
                    trailing: Image.memory(
                      apps![index] is ApplicationWithIcon ? apps![index].icon : null,
                      height: 40,
                    ),
                    subtitle: Text(
                      apps![index].packageName,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
              child:

                  // ListView.builder(
                  //     itemCount: infos!.length,
                  //     shrinkWrap: true,
                  //     itemBuilder: (context, index) {
                  //       return InkWell(
                  //         onTap: () {},
                  //         child: ListTile(
                  //           title: Text(
                  //             infos![index].appName,
                  //           ),
                  //           subtitle: Text(
                  //             infos![index].packageName,
                  //           ),
                  //           trailing: Text(
                  //             (infos![index]
                  //                 .endDate
                  //                 .difference(DateTime(DateTime.now().year, DateTime.now().month,
                  //                     DateTime.now().day, 0, 0, 0))
                  //                 .toString()),
                  //           ),
                  //         ),
                  //       );
                  //     }),

                  ListView.builder(
            itemCount: infos!.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              infos!.sort((a, b) => b.endDate.compareTo(a.endDate));
              final endDateDifference = infos![index].endDate.difference(
                  DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0));

              return InkWell(
                onTap: () {},
                child: ListTile(
                  title: Text(
                    infos![index].appName,
                  ),
                  subtitle: Text(
                    infos![index].packageName,
                  ),
                  trailing: Text(
                    endDateDifference.toString(),
                  ),
                ),
              );
            },
          )),
          // Expanded(
          //   child: PDFView(
          //     filePath: Uri.encodeFull('https://www.africau.edu/images/default/sample.pdf'),
          //     enableSwipe: true,
          //     swipeHorizontal: true,
          //     autoSpacing: false,
          //     pageFling: false,
          //     onError: (error) {
          //       print(error.toString());
          //     },
          //     onPageError: (page, error) {
          //       print('$page: ${error.toString()}');
          //     },
          //     onViewCreated: (PDFViewController pdfViewController) {},
          //   ),
          // )
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: getUsageStats,
            child: const Icon(
              Icons.file_download,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: getApp,
            child: const Icon(
              Icons.replay_circle_filled_rounded,
            ),
          ),
        ],
      ),
    );
  }
}
