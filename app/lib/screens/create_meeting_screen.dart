import 'package:flutter/material.dart';
import '../services/meeting_service.dart';
import '../services/user_service.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {

  final _titleCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();

  DateTime? meetingDate;

  List<dynamic> users = [];
  List<String> selectedParticipants = [];

  List<Map<String,dynamic>> tasks = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  void loadUsers() async {

  final data = await UserService.getUsers();

  print("USERS FROM API:");
  print(data);

  setState(() {
    users = data;
  });

}
  Future<void> pickMeetingDate() async {

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if(picked!=null){
      setState(()=>meetingDate= picked);
    }

  }

  Future<void> pickDeadline(int index) async {

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );

    if(picked!=null){
      setState(() {
        tasks[index]["deadline"]=picked.toIso8601String();
      });
    }

  }

  void addTask(){

    setState(() {

      tasks.add({
        "title":"",
        "action":"",
        "category":"Quality",
        "assignedTo":"",
        "deadline":null
      });

    });

  }

  Future<void> createMeeting() async {

    if(_titleCtrl.text.isEmpty || meetingDate==null) return;

    setState(()=>loading=true);

    final data = {

      "title":_titleCtrl.text,
      "client":_clientCtrl.text,
      "date":meetingDate!.toIso8601String(),
      "participants":selectedParticipants,
      "tasks":tasks

    };

    final res = await MeetingService.createMeeting(data);

    setState(()=>loading=false);

    if(res["message"]=="Meeting created"){

      Navigator.pop(context);

    }else{

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(res["message"])));

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Create Meeting"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            const Text("Meeting Details",
            style: TextStyle(fontSize:18,fontWeight:FontWeight.bold)),

            const SizedBox(height:10),

            TextField(
              controller:_titleCtrl,
              decoration:const InputDecoration(labelText:"Meeting Title"),
            ),

            const SizedBox(height:10),

            TextField(
              controller:_clientCtrl,
              decoration:const InputDecoration(labelText:"Client / Project"),
            ),

            const SizedBox(height:10),

            InkWell(
              onTap:pickMeetingDate,
              child:InputDecorator(
                decoration:const InputDecoration(labelText:"Meeting Date"),
                child:Text(
                  meetingDate==null
                      ?"Select Date"
                      :"${meetingDate!.day}/${meetingDate!.month}/${meetingDate!.year}"
                ),
              ),
            ),

            const SizedBox(height:20),

            const Text("Participants",
            style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),

            const SizedBox(height:10),

            users.isEmpty
            ? const Text("No users found")
            : Wrap(
                children: users.map((u){

                  final selected =
                  selectedParticipants.contains(u["_id"]);

                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: FilterChip(
                      label: Text(u["username"]),
                      selected: selected,
                      onSelected: (_) {

                        setState(() {

                          if(selected){
                            selectedParticipants.remove(u["_id"]);
                          }else{
                            selectedParticipants.add(u["_id"]);
                          }

                        });

                      },
                    ),
                  );

                }).toList(),
            ),

            const SizedBox(height:20),

            Row(
              mainAxisAlignment:MainAxisAlignment.spaceBetween,
              children: [

                const Text("Tasks",
                style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),

                IconButton(
                  icon:const Icon(Icons.add),
                  onPressed:addTask,
                )

              ],
            ),

            ...tasks.asMap().entries.map((entry){

              int index = entry.key;
              var task = entry.value;

              return Card(
                margin:const EdgeInsets.symmetric(vertical:8),
                child:Padding(
                  padding:const EdgeInsets.all(10),
                  child:Column(
                    children: [

                      TextField(
                        decoration:const InputDecoration(
                            labelText:"Task Title"),
                        onChanged:(v)=>task["title"]=v,
                      ),

                      DropdownButtonFormField<String>(
  value: task["category"],
  items: const [
    DropdownMenuItem(value: "Quality", child: Text("Quality")),
    DropdownMenuItem(value: "Cost", child: Text("Cost")),
    DropdownMenuItem(value: "Delivery", child: Text("Delivery")),
    DropdownMenuItem(value: "Development", child: Text("Development")),
    DropdownMenuItem(value: "Engineering", child: Text("Engineering")),
    DropdownMenuItem(value: "Others", child: Text("Others")),
  ],
  onChanged: (v) {
    setState(() {
      task["category"] = v;
    });
  },
  decoration: const InputDecoration(
    labelText: "Category",
  ),
),

                      TextField(
                        decoration:const InputDecoration(
                            labelText:"Action"),
                        onChanged:(v)=>task["action"]=v,
                      ),

                      DropdownButtonFormField(

                        value:task["assignedTo"]==""?null:task["assignedTo"],

                        items:users
                            .where((u)=>selectedParticipants
                            .contains(u["_id"]))
                            .map((u){

                          return DropdownMenuItem(
                            value:u["_id"],
                            child:Text(u["username"]),
                          );

                        }).toList(),

                        onChanged:(v)=>task["assignedTo"]=v,

                        decoration:const InputDecoration(
                          labelText:"Assign To"
                        ),

                      ),

                      const SizedBox(height:10),

                      InkWell(
                        onTap:()=>pickDeadline(index),
                        child:InputDecorator(
                          decoration:const InputDecoration(
                            labelText:"Deadline"
                          ),
                          child:Text(
                            task["deadline"]==null
                                ?"Select Deadline"
                                :task["deadline"]
                                .toString()
                                .split("T")[0],
                          ),
                        ),
                      )

                    ],
                  ),
                ),
              );

            }),

            const SizedBox(height:20),

            loading
                ?const Center(child:CircularProgressIndicator())
                :ElevatedButton(
                    onPressed:createMeeting,
                    child:const Text("Create Meeting"),
                )

          ],
        ),
      ),
    );
  }
}