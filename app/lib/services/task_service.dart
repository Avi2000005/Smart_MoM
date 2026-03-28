import 'api_service.dart';

class TaskService {

  static Future getTasks() async {
    return await ApiService.get("tasks");
  }

  static Future createTask(Map data) async {
    return await ApiService.post("tasks", data);
  }

  static Future toggleTask(String taskId, String meetingId) async {

    return await ApiService.patch(
      "tasks/$taskId",
      {
        "meetingId": meetingId
      },
    );

  }

  static Future deleteTask(String taskId, String meetingId) async {

    return await ApiService.delete(
      "tasks/$taskId?meetingId=$meetingId"
    );

  }

}