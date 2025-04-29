import 'package:flutter/material.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/models/ticket.dart';
import 'package:http/http.dart' as http;

class Ticket extends StatefulWidget {
  const Ticket({super.key, required this.controller});
  static String id = 'ticket_screen';
  final PageController controller;

  @override
  State<Ticket> createState() => _TicketState();
}

class _TicketState extends State<Ticket> {
  List<TicketModel> _ticket = [];
  bool _isLoading = true;
  String _getDeviceStatus = '';

  @override
  void initState() {
    super.initState();
    _getTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 20),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Thiết bị',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Danh sách thiết bị với Pull-to-Refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isLoading = true; // Đặt trạng thái tải lại
                });
                await _getTickets(); // Gọi hàm tải lại thiết bị
                setState(() {
                  _isLoading = false; // Đặt trạng thái không tải lại
                });
              }, // Hàm tải lại thiết bị
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _ticket.isNotEmpty
                      ? ListView.builder(
                        padding: EdgeInsets.all(20),
                        itemCount: _ticket.length,
                        itemBuilder: (context, index) {
                          final ticket = _ticket[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => DeviceDetailScreen(
                                        deviceId: device.getId(),
                                        deviceName: device.getName(),
                                        controller: widget.controller,
                                      ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Icon(
                                    //   Icons.circle,
                                    //   color:
                                    //       device.getIsOnline()
                                    //           ? Colors.green
                                    //           : Colors.red,
                                    // ),
                                    const SizedBox(width: 10),
                                    Text(
                                      ticket.getBriefDescription(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        ticket.status == "InProgress"
                                            ? "Đang xử lý"
                                            : ticket.status == "Pending"
                                            ? "Đang chờ"
                                            : ticket.status == "Closed"
                                            ? "Đã đóng"
                                            : ticket.status == "Done"
                                            ? "Đã hoàn thành"
                                            : ticket.status == "IsTransferring"
                                            ? "Đang chuyển hỗ trợ"
                                            : "Chuyển bị từ chối",
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Thể loại: ${ticket.type == "Shopping" ? "Mua hàng" : "Kỹ thuật"}',
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          );
                        },
                      )
                      : const Center(
                        child: Text(
                          'Không có phiếu hỗ trợ nào',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),

      // Nút thêm thiết bị
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateTicket()),
          );
        },
        tooltip: 'Thêm thiết bị',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _getTickets() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa
    final response = await http.get(
      Uri.parse('${apiUrl}user/me/devices'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
    );
  }
}

class CreateTicket extends StatefulWidget {
  const CreateTicket({super.key});

  @override
  State<CreateTicket> createState() => _CreateTicketState();
}

class _CreateTicketState extends State<CreateTicket> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class TicketDetail extends StatefulWidget {
  const TicketDetail({super.key});

  @override
  State<TicketDetail> createState() => _TicketDetailState();
}

class _TicketDetailState extends State<TicketDetail> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
