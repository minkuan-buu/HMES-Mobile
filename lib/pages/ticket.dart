import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hmes/helper/logout.dart';
import 'package:hmes/helper/secureStorageHelper.dart';
import 'package:hmes/context/baseAPI_URL.dart';
import 'package:hmes/models/ticket.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  String getStatusLabel(String status) {
    switch (status) {
      case "InProgress":
        return "Đang xử lý";
      case "Pending":
        return "Đang chờ";
      case "Closed":
        return "Đã đóng";
      case "Done":
        return "Đã hoàn thành";
      case "IsTransferring":
        return "Đang chuyển hỗ trợ";
      default:
        return "Chuẩn bị từ chối";
    }
  }

  // Hàm trả về màu theo trạng thái
  Color getStatusColor(String status) {
    switch (status) {
      case "InProgress":
        return Colors.blue;
      case "Pending":
        return Colors.amber;
      case "Closed":
        return Colors.red;
      case "Done":
        return Colors.green;
      case "IsTransferring":
        return Colors.purple;
      default:
        return Colors.red;
    }
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
                  'Phiếu hỗ trợ',
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
                            onTap: () async {
                              final result = await Navigator.push(
                                this.context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TicketDetail(
                                        ticketId: ticket.getId(),
                                        controller: widget.controller,
                                      ),
                                ),
                              );

                              // Refresh the ticket list when returning from TicketDetail
                              // in case the ticket status has changed
                              setState(() {
                                _isLoading = true;
                              });
                              _getTickets();
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ticket.getBriefDescription(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        getStatusLabel(ticket.status),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: getStatusColor(
                                        ticket.status,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Loại hỗ trợ: ${ticket.type == "Shopping" ? "Mua hàng" : "Kỹ thuật"}',
                                ),
                                Divider(
                                  color: Colors.grey,
                                  thickness: 0.5,
                                  height: 20,
                                ),
                                const SizedBox(height: 10),
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTicket(controller: widget.controller),
            ),
          );

          // Check if the result is true, which means a ticket was created
          if (result == true) {
            setState(() {
              _isLoading = true;
            });
            _getTickets();
          }
        },
        tooltip: 'Thêm thiết bị',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _goToCreateTicket() {
    final result = Navigator.push(
      this.context,
      MaterialPageRoute(
        builder: (context) => CreateTicket(controller: widget.controller),
      ),
    );
    result.then((value) {
      if (value != null && value == true) {
        setState(() {
          _isLoading = true; // Đặt trạng thái tải lại
        });
        _getTickets(); // Gọi hàm tải lại thiết bị
      }
    });
  }

  Future<void> _getTickets() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa
    final response = await http.get(
      Uri.parse('${apiUrl}ticket?pageSize=1000'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      List<dynamic> dataList = responseJson['response']?['data'] ?? [];
      _ticket = dataList.map((item) => TicketModel.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (response.statusCode == 401) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (context) => Logout(controller: widget.controller),
            ),
          );
        });
      }
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _getDeviceStatus = responseJson['message'];

      if (mounted) {
        Fluttertoast.showToast(
          msg: _getDeviceStatus,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.black,
          fontSize: 16.0,
        );
        setState(() {
          _isLoading = false;
        });

        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (mounted) {
        //     Navigator.pop(context);
        //   }
        // });
      }
    }
  }
}

class CreateTicket extends StatefulWidget {
  const CreateTicket({super.key, required this.controller});
  static String id = 'create_ticket_screen';
  final PageController controller;

  @override
  State<CreateTicket> createState() => _CreateTicketState();
}

class _CreateTicketState extends State<CreateTicket> {
  String? selectedType = 'Shopping';
  List<DeviceItemTicket>? _deviceItemTicket;
  bool _isLoadingDevice = false;
  bool _isTicketSending = false;
  late TextEditingController _responseController;
  String _ticketDescription = '';
  String _getDeviceStatus = '';
  String? selectedDeviceId;
  String _getTicketStatus = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _responseController = TextEditingController();
  }

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      resizeToAvoidBottomInset: true, // Cho phép body co lại khi bàn phím hiện
      appBar: AppBar(
        title: Text('Tạo yêu cầu hỗ trợ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ),
      // Wrap the entire body in a SingleChildScrollView to make it scrollable
      body: SingleChildScrollView(
        // Add padding to ensure content doesn't get hidden behind keyboard
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mô tả yêu cầu hỗ trợ',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: 'Chọn loại yêu cầu hỗ trợ',
                  border: OutlineInputBorder(), // <-- Đây là khung viền
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items:
                    <String>['Mua hàng', 'Kỹ thuật'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value == 'Mua hàng' ? 'Shopping' : 'Technical',
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue;
                  });
                  if (newValue == "Technical") {
                    setState(() {
                      _isLoadingDevice = true;
                    });
                    _loadDeviceItem(); // Gọi hàm tải lại thiết bị
                  }
                },
              ),
              const SizedBox(height: 20),
              if (selectedType == "Technical")
                _isLoadingDevice
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<String>(
                      value: selectedDeviceId,
                      decoration: const InputDecoration(
                        labelText: 'Chọn thiết bị',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      items:
                          _deviceItemTicket?.map((device) {
                            return DropdownMenuItem<String>(
                              value: device.id,
                              child: SizedBox(
                                width: screenWidth * 0.75,
                                child: Text(
                                  "${device.name} - ${device.id}",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newId) {
                        setState(() {
                          selectedDeviceId = newId;
                        });
                      },
                    ),

              const SizedBox(height: 20),
              TextField(
                controller: _responseController,
                onChanged: (value) {
                  setState(() {
                    _ticketDescription = value;
                  });
                },
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Nhập mô tả yêu cầu hỗ trợ',
                  border: OutlineInputBorder(), // <-- Đây là khung viền
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(
                                  File(_selectedImages[index].path),
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _pickImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9F7BFF),
                    ),
                    child: const Text(
                      'Thêm tệp đính kèm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_ticketDescription.isEmpty || _isTicketSending) {
                        Fluttertoast.showToast(
                          msg: 'Vui lòng nhập mô tả yêu cầu hỗ trợ',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          textColor: Colors.black,
                          fontSize: 16.0,
                        );
                        return;
                      }
                      _sendTicket();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9F7BFF),
                    ),
                    child: const Text(
                      'Gửi yêu cầu hỗ trợ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              // Add padding at the bottom to ensure content is not hidden by keyboard
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendTicket() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    setState(() {
      _isTicketSending = true; // Đặt trạng thái tải lại
    });

    final uri = Uri.parse('${apiUrl}ticket');
    final request = http.MultipartRequest('POST', uri);

    // Headers (chỉ cần Cookie và Authorization, KHÔNG cần Content-Type)
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
    });

    request.fields['Type'] = selectedType ?? '';

    if (selectedType == "Technical") {
      request.fields['DeviceId'] = selectedDeviceId ?? '';
    }

    // Gửi message (field text)
    request.fields['Description'] = _ticketDescription;

    // Gửi file đính kèm nếu có
    for (var file in _selectedImages) {
      if (file != null && File(file.path).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'Attachments', // key phải đúng như BE yêu cầu
            file.path,
            filename: basename(file.path),
          ),
        );
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      String? newAccessToken = response.headers['new-access-token'];
      if (newAccessToken != null) {
        await updateToken(newAccessToken);
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Phản hồi đã được gửi thành công');
        setState(() {
          _isTicketSending = false;
          _selectedImages.clear();
          _responseController.clear();
        });
        // Return to the previous screen after successful submission with result=true
        // to indicate that a refresh is needed
        Navigator.pop(this.context, true);
      } else if (response.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (context) => Logout(controller: widget.controller),
            ),
          );
        });
      } else {
        final responseJson = jsonDecode(response.body);
        _getTicketStatus = responseJson['message'];
        Fluttertoast.showToast(msg: _getTicketStatus);
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Lỗi gửi phản hồi: $e');
    } finally {
      setState(() {
        _isTicketSending = false; // Đặt lại trạng thái tải lại
      });
    }
  }

  Future<void> _loadDeviceItem() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa
    final response = await http.get(
      Uri.parse('${apiUrl}device/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      List<dynamic> dataList = responseJson['response']?['data'] ?? [];
      _deviceItemTicket =
          dataList.map((item) => DeviceItemTicket.fromJson(item)).toList();

      if (mounted) {
        setState(() {
          _isLoadingDevice = false;
        });
      }
    } else if (response.statusCode == 401) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (context) => Logout(controller: widget.controller),
            ),
          );
        });
      }
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _getDeviceStatus = responseJson['message'];

      if (mounted) {
        Fluttertoast.showToast(
          msg: _getDeviceStatus,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.black,
          fontSize: 16.0,
        );
        setState(() {
          _isLoadingDevice = false;
        });

        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (mounted) {
        //     Navigator.pop(context);
        //   }
        // });
      }
    }
  }
}

class TicketDetail extends StatefulWidget {
  const TicketDetail({
    super.key,
    required this.ticketId,
    required this.controller,
  });
  final String ticketId;
  final PageController controller;

  @override
  State<TicketDetail> createState() => _TicketDetailState();
}

class _TicketDetailState extends State<TicketDetail> {
  late TicketDetailModel _ticketDetail;
  late TextEditingController _responseController;
  bool _isLoading = true;
  String _getTicketStatus = '';
  String _responseMessage = '';
  bool _isResponseSending = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getTicketDetail();
    _responseController = TextEditingController();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  String formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm, dd/MM/yyyy').format(dateTime);
  }

  String getStatusLabel(String status) {
    switch (status) {
      case "InProgress":
        return "Đang xử lý";
      case "Pending":
        return "Đang chờ";
      case "Closed":
        return "Đã đóng";
      case "Done":
        return "Đã hoàn thành";
      case "IsTransferring":
        return "Đang chuyển hỗ trợ";
      default:
        return "Chuẩn bị từ chối";
    }
  }

  // Hàm trả về màu theo trạng thái
  Color getStatusColor(String status) {
    switch (status) {
      case "InProgress":
        return Colors.blue;
      case "Pending":
        return Colors.amber;
      case "Closed":
        return Colors.red;
      case "Done":
        return Colors.green;
      case "IsTransferring":
        return Colors.purple;
      default:
        return Colors.red;
    }
  }

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('Chi tiết phiếu hỗ trợ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Return true to indicate the ticket page should refresh
            Navigator.pop(context, true);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isLoading = true;
                });
                await _getTicketDetail();
                setState(() {
                  _isLoading = false;
                });
              },
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _ticketDetail != null
                      ? Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              top: 15,
                              bottom: 15,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _ticketDetail.description,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    getStatusLabel(_ticketDetail.status),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                  backgroundColor: getStatusColor(
                                    _ticketDetail.status,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                Text(
                                  'Loại hỗ trợ: ${_ticketDetail.type == "Shopping" ? "Mua hàng" : "Kỹ thuật"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _ticketDetail.type == "Technical"
                                    ? Text(
                                      'Serial: ${_ticketDetail.deviceItemSerial}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : const SizedBox(),
                                Text(
                                  'Thời gian tạo phiếu hỗ trợ: ${formatDateTime(_ticketDetail.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _ticketDetail.attachments.isNotEmpty
                                    ? SizedBox(
                                      height: 90,
                                      child: Center(
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          shrinkWrap: true,
                                          itemCount:
                                              _ticketDetail.attachments.length,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) => ImageViewScreen(
                                                          imageUrl:
                                                              _ticketDetail
                                                                  .attachments[index]!,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                      _ticketDetail
                                                          .attachments[index]!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                    : const SizedBox(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _ticketDetail.ticketResponses.length,
                              itemBuilder: (context, index) {
                                final response =
                                    _ticketDetail.ticketResponses[index];
                                final isOwner =
                                    response?.userId == _ticketDetail.createdBy;

                                return Align(
                                  alignment:
                                      isOwner
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                  child: Container(
                                    width:
                                        screenWidth *
                                        0.7, // Chiếm 70% chiều rộng màn hình
                                    margin: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.01,
                                      horizontal: screenWidth * 0.025,
                                    ),
                                    padding: EdgeInsets.all(
                                      screenWidth * 0.025,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isOwner
                                              ? Colors.blue[100]
                                              : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          isOwner
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          response?.userFullName ?? '',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        Text(
                                          response?.message ?? '',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.05,
                                          ),
                                        ),
                                        if (response?.attachments.isNotEmpty ??
                                            false)
                                          Row(
                                            mainAxisAlignment:
                                                isOwner
                                                    ? MainAxisAlignment.end
                                                    : MainAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 90,
                                                child: ListView.builder(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  shrinkWrap: true,
                                                  itemCount:
                                                      response!
                                                          .attachments
                                                          .length,
                                                  itemBuilder: (
                                                    context,
                                                    index,
                                                  ) {
                                                    return GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => ImageViewScreen(
                                                                  imageUrl:
                                                                      response
                                                                          .attachments[index]!,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              right: 8,
                                                            ),
                                                        width: 80,
                                                        height: 80,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          image: DecorationImage(
                                                            image: NetworkImage(
                                                              response
                                                                  .attachments[index]!,
                                                            ),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(height: 5),
                                        Text(
                                          response?.createdAt != null
                                              ? formatDateTime(
                                                response!.createdAt!,
                                              )
                                              : '',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.028,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.015,
                              horizontal: screenWidth * 0.02,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child:
                                _ticketDetail.status == "InProgress"
                                    ? Column(
                                      children: [
                                        // Hiển thị ảnh đính kèm nếu có
                                        if (_selectedImages.isNotEmpty)
                                          SizedBox(
                                            height: 90,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: _selectedImages.length,
                                              itemBuilder: (context, index) {
                                                return Stack(
                                                  children: [
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            right: 8,
                                                          ),
                                                      width: 80,
                                                      height: 80,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        image: DecorationImage(
                                                          image: FileImage(
                                                            File(
                                                              _selectedImages[index]
                                                                  .path,
                                                            ),
                                                          ),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 2,
                                                      right: 2,
                                                      child: GestureDetector(
                                                        onTap:
                                                            () => _removeImage(
                                                              index,
                                                            ),
                                                        child:
                                                            const CircleAvatar(
                                                              radius: 10,
                                                              backgroundColor:
                                                                  Colors
                                                                      .black54,
                                                              child: Icon(
                                                                Icons.close,
                                                                size: 12,
                                                                color:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),

                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.attach_file,
                                              ),
                                              onPressed: _pickImages,
                                            ),
                                            Expanded(
                                              child: TextField(
                                                controller: _responseController,
                                                decoration: InputDecoration(
                                                  border:
                                                      const OutlineInputBorder(),
                                                  label: Text(
                                                    'Nhập phản hồi của bạn',
                                                    style: TextStyle(
                                                      fontSize:
                                                          screenWidth * 0.035,
                                                    ),
                                                  ),
                                                ),

                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.04,
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _responseMessage = value;
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(width: screenWidth * 0.02),
                                            _isResponseSending
                                                ? const SizedBox(
                                                  width: 35,
                                                  height: 35,
                                                  child:
                                                      CircularProgressIndicator(),
                                                )
                                                : IconButton(
                                                  color:
                                                      _responseMessage.isEmpty
                                                          ? Colors.grey
                                                          : Colors.blue,
                                                  icon: const Icon(Icons.send),
                                                  onPressed: () {
                                                    if (_responseMessage
                                                            .isEmpty ||
                                                        _isResponseSending) {
                                                      Fluttertoast.showToast(
                                                        msg:
                                                            'Vui lòng nhập phản hồi',
                                                        toastLength:
                                                            Toast.LENGTH_SHORT,
                                                        gravity:
                                                            ToastGravity.BOTTOM,
                                                        timeInSecForIosWeb: 1,
                                                        textColor: Colors.black,
                                                        fontSize: 16.0,
                                                      );
                                                      return;
                                                    }
                                                    _sendResponse();
                                                    // Gửi phản hồi
                                                  },
                                                ),
                                          ],
                                        ),
                                      ],
                                    )
                                    : Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Yêu cầu hỗ trợ đã ${getStatusLabel(_ticketDetail.status).toLowerCase()}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: getStatusColor(
                                              _ticketDetail.status,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                          ),
                        ],
                      )
                      : const Center(
                        child: Text(
                          'Không có thông tin chi tiết nào',
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
    );
  }

  Future<void> _sendResponse() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    setState(() {
      _isResponseSending = true; // Đặt trạng thái tải lại
    });

    final uri = Uri.parse('${apiUrl}ticket/response');
    final request = http.MultipartRequest('POST', uri);

    // Headers (chỉ cần Cookie và Authorization, KHÔNG cần Content-Type)
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
    });

    request.fields['TicketId'] = widget.ticketId; // Gửi ticketId

    // Gửi message (field text)
    request.fields['Message'] = _responseMessage;

    // Gửi file đính kèm nếu có
    for (var file in _selectedImages) {
      if (file != null && File(file.path).existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'Attachments', // key phải đúng như BE yêu cầu
            file.path,
            filename: basename(file.path),
          ),
        );
      }
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      String? newAccessToken = response.headers['new-access-token'];
      if (newAccessToken != null) {
        await updateToken(newAccessToken);
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: 'Phản hồi đã được gửi thành công');
        setState(() {
          _selectedImages.clear();
          _responseController.clear();
          _responseMessage = ''; // Reset lại message
        });

        // Immediately reload the ticket detail
        _getTicketDetail();
      } else if (response.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (context) => Logout(controller: widget.controller),
            ),
          );
        });
      } else {
        final responseJson = jsonDecode(response.body);
        _getTicketStatus = responseJson['message'];
        Fluttertoast.showToast(msg: _getTicketStatus);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Lỗi gửi phản hồi: $e');
    } finally {
      setState(() {
        _isResponseSending = false; // Đặt lại trạng thái tải lại
      });
    }
  }

  Future<void> _getTicketDetail() async {
    String token = (await getToken()).toString();
    String refreshToken = (await getRefreshToken()).toString();
    String deviceId = (await getDeviceId()).toString();

    if (!mounted) return; // Kiểm tra widget đã bị unmount hay chưa
    final response = await http.get(
      Uri.parse('${apiUrl}ticket/${widget.ticketId}'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'DeviceId=$deviceId; RefreshToken=$refreshToken',
        'Authorization': 'Bearer $token',
      },
    );

    String? newAccessToken = response.headers['new-access-token'];
    if (newAccessToken != null) {
      await updateToken(newAccessToken);
    }

    if (!mounted) return; // Kiểm tra lại widget trước khi setState

    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      Map<String, dynamic> data = responseJson['response']?['data'] ?? {};
      _ticketDetail = TicketDetailModel.fromJson(data);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (response.statusCode == 401) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            this.context,
            MaterialPageRoute(
              builder: (context) => Logout(controller: widget.controller),
            ),
          );
        });
      }
    } else {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      _getTicketStatus = responseJson['message'];

      if (mounted) {
        Fluttertoast.showToast(
          msg: _getTicketStatus,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          textColor: Colors.black,
          fontSize: 16.0,
        );
        setState(() {
          _isLoading = false;
        });

        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   if (mounted) {
        //     Navigator.pop(context);
        //   }
        // });
      }
    }
  }
}

class ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(child: InteractiveViewer(child: Image.network(imageUrl))),
    );
  }
}
