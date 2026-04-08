import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {

  Map<String,dynamic> data = {};
  bool loading = true;

  @override
  void initState(){
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {

    final result = await DashboardService.getDashboard();

    setState(() {
      data = result;
      loading = false;
    });

  }

  /// TOP 10 USERS FOR CHART
  List<Map<String,dynamic>> get topParticipants {

    List<Map<String,dynamic>> participants =
        List<Map<String,dynamic>>.from(data["participants"] ?? []);

    participants.sort((a,b){

      int r1 = a["completionRate"] ?? 0;
      int r2 = b["completionRate"] ?? 0;

      return r2.compareTo(r1);

    });

    return participants.take(10).toList();

  }

  /// METRIC CARD
  Widget statCard(String title,dynamic value,IconData icon,Color color){

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff1f1f38),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,color: color),
          ),

          const SizedBox(width:12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  value.toString(),
                  style: const TextStyle(
                      fontSize:22,
                      fontWeight: FontWeight.bold
                  ),
                ),

                Text(
                  title,
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                )

              ],
            ),
          )

        ],
      ),
    );

  }

  /// DONUT CHART
  Widget completionChart(){

    final completed = (data["completedTasks"] ?? 0).toDouble();
    final pending = (data["pendingTasks"] ?? 0).toDouble();

    return PieChart(

      PieChartData(

        centerSpaceRadius: 70,
        sectionsSpace: 4,

        sections: [

          PieChartSectionData(
            value: completed,
            color: Colors.green,
            radius: 65,
            title: "",
          ),

          PieChartSectionData(
            value: pending,
            color: Colors.red,
            radius: 65,
            title: "",
          )

        ],

      ),

    );

  }

  /// LEGEND FOR DONUT
  Widget legend(){

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        legendItem(Colors.green,"Completed"),
        const SizedBox(width:20),
        legendItem(Colors.red,"Pending"),

      ],
    );

  }

  Widget legendItem(Color color,String text){

    return Row(
      children: [

        Container(
          width:12,
          height:12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),

        const SizedBox(width:6),

        Text(text)

      ],
    );

  }

  /// PARTICIPANT CHART
  Widget participantChart(){

    final participants = topParticipants;

    return Column(

      children: participants.map((p){

        double rate = (p["completionRate"] ?? 0).toDouble();

        return Padding(

          padding: const EdgeInsets.symmetric(vertical:10),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    p["name"],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("${rate.toInt()}%"),
                ],
              ),

              const SizedBox(height:6),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: rate/100,
                  minHeight: 10,
                  backgroundColor: Colors.grey.withOpacity(.2),
                  valueColor: const AlwaysStoppedAnimation(
                    Color(0xff00f2fe),
                  ),
                ),
              )

            ],
          ),
        );

      }).toList(),

    );

  }

  /// PARTICIPANT TABLE
  Widget participantTable(){

    final participants = data["participants"] ?? [];

    return SizedBox(

      height:400,

      child: SingleChildScrollView(

        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(

          columns: const [

            DataColumn(label: Text("Participant")),
            DataColumn(label: Text("Assigned")),
            DataColumn(label: Text("Completed")),
            DataColumn(label: Text("Completion %")),

          ],

          rows: participants.map<DataRow>((p){

            return DataRow(

              cells: [

                DataCell(Text(p["name"])),

                DataCell(Text(p["assigned"].toString())),

                DataCell(Text(p["completed"].toString())),

                DataCell(Text("${p["completionRate"]}%")),

              ],

            );

          }).toList(),

        ),
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context){

    if(loading){
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: ListView(

          children: [

            /// METRIC CARDS
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: statCard("Meetings", data["totalMeetings"], Icons.calendar_month, Colors.blue)),
                          const SizedBox(width:16),
                          Expanded(child: statCard("Tasks", data["totalTasks"], Icons.task, Colors.orange)),
                        ],
                      ),
                      const SizedBox(height:16),
                      Row(
                        children: [
                          Expanded(child: statCard("Completed", data["completedTasks"], Icons.check, Colors.green)),
                          const SizedBox(width:16),
                          Expanded(child: statCard("Pending", data["pendingTasks"], Icons.pending, Colors.red)),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: statCard("Meetings", data["totalMeetings"], Icons.calendar_month, Colors.blue)),
                    const SizedBox(width:16),
                    Expanded(child: statCard("Tasks", data["totalTasks"], Icons.task, Colors.orange)),
                    const SizedBox(width:16),
                    Expanded(child: statCard("Completed", data["completedTasks"], Icons.check, Colors.green)),
                    const SizedBox(width:16),
                    Expanded(child: statCard("Pending", data["pendingTasks"], Icons.pending, Colors.red)),
                  ],
                );
              },
            ),

            const SizedBox(height:30),

            /// CHARTS
            LayoutBuilder(
              builder: (context, constraints) {
                final donutChartSection = Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff1f1f38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Task Completion",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height:20),
                      SizedBox(
                        height:260,
                        child: completionChart(),
                      ),
                      const SizedBox(height:15),
                      legend(),
                    ],
                  ),
                );

                final participantChartSection = Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff1f1f38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Top Participants",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height:10),
                      participantChart(),
                    ],
                  ),
                );

                if (constraints.maxWidth < 800) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      donutChartSection,
                      const SizedBox(height:20),
                      participantChartSection,
                    ],
                  );
                }
                
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: donutChartSection),
                    const SizedBox(width:20),
                    Expanded(child: participantChartSection),
                  ],
                );
              },
            ),

            const SizedBox(height:30),

            const Text(
              "Participant Performance",
              style: TextStyle(
                fontSize:18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height:10),

            participantTable(),

          ],
        ),
      ),
    );

  }

}