import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nk_push_app/Utils/util.dart';
import 'package:nk_push_app/constants/url_constants.dart';
import 'package:nk_push_app/frame/navigation_fab_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 채팅방 선택 여부
  Map<String, dynamic>? selectedChatRoom;
  List<Map<String, dynamic>> chatRooms = []; // 채팅방 목록
  List<Map<String, dynamic>> messages = []; // 샘플 채팅 메시지
  TextEditingController messageController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  bool isSearching = true;
  bool isLoading = true;
  String comp = ''; // 회사 코드
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> searchResults = []; // 검색 결과
  OverlayEntry? overlayEntry; // OverlayEntry를 저장할 변수
  final LayerLink layerLink = LayerLink(); // 검색창 위치 추적
  late HubConnection hubConnection;
  bool connectionIsOpen = false;
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchNodeFocused = false;
  int chatRoomListPage = 1;
  int chatRoomListPageSize = 10;
  int offset = 0;
  final ScrollController _scrollController = ScrollController();
  String? connectionId = null;
  String? parameter = null;
  String? searchId = null;

  @override
  void initState() {
    super.initState();
    _initializeData(); // 초기 데이터 로드
    // 포커스 상태 변화 감지
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchNodeFocused = _searchFocusNode.hasFocus; // 현재 포커스 여부 저장
      });
      _showOverlay();
    });
  }

  @override
  void dispose() {
    leaveChatRoom(); // 채팅방 나가기 요청
    hubConnection.stop();
    super.dispose();
  }

  final RegExp urlRegex = RegExp(
    r'^(https?:\/\/)?([\w\d-]+\.)+[\w\d]{2,}(\/\S*)?$',
    caseSensitive: false,
  );

  void leaveChatRoom() async {
    setState(() {
      messages.clear();
    });
    if (hubConnection.state == HubConnectionState.Connected &&
        selectedChatRoom != null) {
      await hubConnection
          .invoke("LeaveChatRoom", args: [selectedChatRoom?['CHAT_ROOM_ID']]);
    }
  }

  void _changeChatRoom(Map<String, dynamic>? room) async {
    setState(() {
      selectedChatRoom = room;
      isSearching = false;
      searchResults.clear();
      messages.clear();
    });
    await hubConnection.invoke("GetMessages", args: [
      selectedChatRoom?['CHAT_ROOM_ID'],
      userData?['PSPSN_NO'],
      offset
    ]);
  }

  Future<void> markMessagesAsRead() async {
    hubConnection.invoke("SetMessageRead", args: [
      selectedChatRoom?['CHAT_ROOM_ID'],
      userData?['PSPSN_NO'],
      offset
    ]);
  }

  Future<void> _initializeData() async {
    setState(() => isLoading = true);
    userData = await loadUserData(); // 로컬 저장소에서 사용자 데이터 로드
    initializeSignalR();
    setState(() => isLoading = false);
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      setState(() {
        parameter = args;
      });
    }
  }

  Future<Map<String, dynamic>> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('user'); // 저장된 사용자 데이터
    comp = prefs.getString('comp').toString(); // 저장된 회사 코드
    return userData != null ? jsonDecode(userData) : {}; // JSON 파싱 후 반환
  }

  Future<void> initializeSignalR() async {
    // SignalR 서버 엔드포인트 설정
    print("🔄 SignalR 연결 초기화 시작...");
    hubConnection = HubConnectionBuilder()
        .withUrl(
          "${UrlConstants.url}/chatHub?userId=${userData?['PSPSN_NO']}",
          options: HttpConnectionOptions(
            transport: HttpTransportType.WebSockets, // WebSockets 우선 사용
            skipNegotiation: true, // 협상(negotiation) 활성화
          ),
        )
        .build();

    hubConnection.onreconnecting(({error}) {
      print("SignalR 재연결 중... : $error");
    });

    hubConnection.onreconnected(({connectionId}) {
      print("SignalR 재연결 성공: $connectionId");
    });

    // 연결 상태 감지
    hubConnection.onclose(({error}) {
      print("SignalR 연결 종료. 에러: ${error?.toString()}");
      _reconnect();
    });

    // 검색 결과 수신 핸들러
    hubConnection.on("SearchUsersResults", (result) {
      try {
        setState(() {
          if (result is List && result.isNotEmpty) {
            // result의 첫 번째 요소가 List인지 확인
            if (result.first is List) {
              // 중첩된 리스트를 펼침
              var nestedList = result.first as List<dynamic>;
              searchResults =
                  nestedList.cast<Map<String, dynamic>>(); // Map으로 변환
            } else {
              print("Unexpected data format inside list: ${result.first}");
            }
          } else {
            print("Unexpected data format: $result");
          }
        });

        _showOverlay();
      } catch (e) {
        print("SearchUsersResults 처리 중 오류: $e");
      }
    });

    hubConnection.on("ChatRoomListResults", (result) async {
      try {
        setState(() {
          if (result is List && result.isNotEmpty) {
            // result의 첫 번째 요소가 List인지 확인
            if (result.first is List) {
              // 중첩된 리스트를 펼침
              var nestedList = result.first as List<dynamic>;
              chatRooms = nestedList.cast<Map<String, dynamic>>(); // Map으로 변환
            } else {
              print("Unexpected data format inside list: ${result.first}");
            }
          } else {
            print("Unexpected data format: $result");
          }
        });
        if (parameter != null) {
          for (var room in chatRooms) {
            if (parameter!.contains(room['CHAT_ROOM_USERS'].toString())) {
              _changeChatRoom(room);
              parameter = null;

              break; // 첫 번째 일치 항목만 처리
            }
          }
        }
      } catch (e) {
        print("ChatRoomListResults 처리 중 오류: $e");
      }
    });

    hubConnection.on("ChatRoomAddListResults", (result) async {
      try {
        await hubConnection.invoke("ChatRoomList", args: [
          userData?['PSPSN_NO'],
          chatRoomListPage,
          chatRoomListPageSize
        ]);

        setState(() {
          if (result is List && result.isNotEmpty) {
            // result의 첫 번째 요소가 List인지 확인
            if (result.first is List) {
              // 중첩된 리스트를 펼침
              var nestedList = result.first as List<dynamic>;
              chatRooms = nestedList.cast<Map<String, dynamic>>(); // Map으로 변환

              selectedChatRoom = chatRooms.firstWhere(
                (room) => room['CHAT_ROOM_USER_NO'] == searchId,
              );

              if (overlayEntry != null) {
                overlayEntry!.remove();
                overlayEntry = null;
                searchResults = []; // 검색 결과 초기화
                searchController.clear(); // 검색창 초기화
              }
            } else {
              print("Unexpected data format inside list: ${result.first}");
            }
          } else {
            print("Unexpected data format: $result");
          }
        });
        if (parameter != null) {
          for (var room in chatRooms) {
            if (parameter!.contains(room['CHAT_ROOM_USERS'].toString())) {
              _changeChatRoom(room);
              parameter = null;

              break; // 첫 번째 일치 항목만 처리
            }
          }
        }
      } catch (e) {
        print("ChatRoomListResults 처리 중 오류: $e");
      }
    });

    hubConnection.on("ChatMessageListResults", (result) async {
      try {
        if (result is List && result.isNotEmpty) {
          if (result.first is List) {
            var newMessages =
                (result.first as List<dynamic>).cast<Map<String, dynamic>>();

            // ✅ 기존 메시지와 비교하여 중복 제거 + 읽음 상태 업데이트
            List<Map<String, dynamic>> updatedMessages = [];
            for (var message in newMessages) {
              bool exists = messages.any((m) =>
                  m['CHAT_ROOM_ID'] == message['CHAT_ROOM_ID'] &&
                  m['MESSAGE_ID'] == message['MESSAGE_ID']);

              if (!exists) {
                // ✅ 새로운 메시지 추가
                updatedMessages.add(message);
              } else {
                // ✅ 기존 메시지 업데이트 (UNREAD_COUNT = 0으로 변경)
                setState(() {
                  messages = messages.map((m) {
                    if (m['CHAT_ROOM_ID'] == message['CHAT_ROOM_ID'] &&
                        m['MESSAGE_ID'] == message['MESSAGE_ID']) {
                      return {
                        ...m,
                        'UNREAD_COUNT': message['UNREAD_COUNT']
                      }; // 읽음 상태로 업데이트
                    }
                    return m;
                  }).toList();
                });
              }
            }

            if (updatedMessages.isNotEmpty) {
              setState(() {
                messages.addAll(updatedMessages);
              });

              markMessagesAsRead();

              // ✅ 새로운 메시지가 추가된 경우 스크롤 자동 이동
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottomAnimated();
              });
            }
          } else {
            print("⚠️ Unexpected data format inside list: ${result.first}");
          }
        } else {
          print("⚠️ Unexpected data format: $result");
        }
      } catch (e) {
        print("🚨 ChatMessageListResults 처리 중 오류: $e");
      }
    });

    hubConnection.on("RefreshChatList", (result) async {
      try {
        await hubConnection.invoke("ChatRoomList", args: [
          userData?['PSPSN_NO'],
          chatRoomListPage,
          chatRoomListPageSize
        ]);
      } catch (e) {
        print("RefreshChatList 처리 중 오류: $e");
      }
    });

    // 서버와 연결
    await hubConnection.start();
    print("✅ SignalR 연결 성공! Connection ID: ${hubConnection.connectionId}");

    setState(() {
      connectionId = hubConnection.connectionId; // connectionId 저장
    });

    await hubConnection.invoke("ChatRoomList",
        args: [userData?['PSPSN_NO'], chatRoomListPage, chatRoomListPageSize]);
  }

  void _reconnect() async {
    for (int i = 0; i < 3; i++) {
      // 최대 3번 재시도
      await Future.delayed(Duration(seconds: 2 * (i + 1))); // 2, 4, 6초 대기 후 재시도
      try {
        await hubConnection.start();
        setState(() {
          connectionId = hubConnection.connectionId;
        });
        print("✅ 재연결 성공! Connection ID: $connectionId");
        return;
      } catch (e) {
        print("🚨 재연결 실패: ${e.toString()} (시도 $i)");
      }
    }
    print("❌ 3번 시도 후 재연결 실패");
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator()) // 로딩 중에는 프로그레스 표시
        : NavigationFABFrame(
            child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF004A99),
              iconTheme: const IconThemeData(color: Colors.white),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              ),
              title: isSearching
                  ? _buildSearchBar() // 검색 모드일 때 TextField 표시
                  : _buildTitle(), // 기본 상태에서 채팅방 이름 표시
              actions: [
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        '${Util.getPictureUrl(comp)}${userData?['PSPSN_PICTURE'].toString()}',
                      ),
                      radius: 18,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],
            ),
            drawer: Drawer(
              width: 300,
              child: Column(
                // Column으로 변경
                children: [
                  const SizedBox(
                    height: 120,
                    child: DrawerHeader(
                      decoration: BoxDecoration(color: Color(0xFF004A99)),
                      child: Center(
                        child: Text(
                          '채팅 목록',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    // 여기서 Expanded 사용
                    child: chatRooms.isEmpty
                        ? ListView(
                            children: const [
                              Center(
                                child: Text(
                                  '채팅 없음',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 3, right: 3),
                            itemCount: chatRooms.length,
                            itemBuilder: (context, index) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Text(
                                  chatRooms[index]['CHAT_ROOM_NAME']
                                          ?.toString() ??
                                      chatRooms[index]['CHAT_ROOM_USERS'][0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                chatRooms[index]['CHAT_ROOM_NAME'] ??
                                    chatRooms[index]['CHAT_ROOM_USERS'],
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: chatRooms[index]['IS_READ'] == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              subtitle: Text(
                                chatRooms[index]['LAST_MESSAGE'] ??
                                    '채팅을 시작하세요.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                  fontWeight: chatRooms[index]['IS_READ'] == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal, // 읽지 않은 메시지는 Bold
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if ((chatRooms[index]['UNREAD_COUNT'] ?? 0) >
                                      0) // 읽지 않은 메시지가 있을 때만 표시
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.red, // 동그라미 배경색
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        chatRooms[index]['UNREAD_COUNT']
                                            .toString(),
                                        style: const TextStyle(
                                          color: Colors.white, // 글씨 색상
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  Text(
                                    (chatRooms[index]['LAST_MESSAGE_DATE'] ??
                                            "")
                                        .replaceAll(" ", "\n"),
                                    style: const TextStyle(
                                      color: Colors.black26,
                                      fontSize: 8,
                                    ),
                                  ), // 날짜와 동그라미 사이 여백
                                ],
                              ),
                              onTap: () async {
                                setState(() {
                                  if (selectedChatRoom != null) {
                                    leaveChatRoom();
                                  }
                                  _changeChatRoom(chatRooms[index]);
                                  isSearching = false;
                                  searchResults.clear();
                                });
                                Navigator.pop(context); // Drawer 닫기
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
            body: selectedChatRoom == null
                ? const Center(
                    child: Text(
                      '채팅을 시작하세요!',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          controller: _scrollController,
                          itemCount: messages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4), // 메시지 간격 추가
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe =
                                userData?['PSPSN_NO'] == message['SENDER_ID'];
                            final unreadCount =
                                message['UNREAD_COUNT'] ?? 0; // 🔹 읽지 않은 메시지 수

                            final String text = message['MESSAGE'] ?? "";

                            final bool isUrl =
                                urlRegex.hasMatch(text); // ✅ URL 여부 확인

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min, // ✅ 내용 크기에 맞게 Row 크기 조정
                                crossAxisAlignment:
                                    CrossAxisAlignment.end, // 🔹 말풍선과 숫자 아래쪽 정렬
                                children: [
                                  if (!isMe &&
                                      unreadCount >
                                          0) // 🔥 보낸 메시지가 아니면서, 안 읽은 경우만 표시
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: Text(
                                        unreadCount.toString(),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.red),
                                      ),
                                    ),
                                  if (isMe &&
                                      unreadCount >
                                          0) // 🔥 내가 보낸 메시지에서 안 읽은 경우만 표시
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Text(
                                        unreadCount.toString(),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.black),
                                      ),
                                    ),
                                  Container(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.blue[100]
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: _buildMessageContent(text)
                                      // isUrl
                                      //     ? InkWell(
                                      //         onTap: () async {
                                      //           Uri url = Uri.parse(text);
                                      //           if (await canLaunchUrl(url)) {
                                      //             await launchUrl(url,
                                      //                 mode: LaunchMode
                                      //                     .externalApplication);
                                      //           } else {
                                      //             print("⚠️ URL 열기 실패: $text");
                                      //           }
                                      //         },
                                      //         child: Text(
                                      //           text,
                                      //           style: const TextStyle(
                                      //             fontSize: 14,
                                      //             color: Colors
                                      //                 .blue, // ✅ URL은 파란색으로 표시
                                      //             decoration: TextDecoration
                                      //                 .underline, // ✅ 밑줄 추가
                                      //           ),
                                      //         ),
                                      //       )
                                      //     : SelectableText(
                                      //         text,
                                      //         style:
                                      //             const TextStyle(fontSize: 14),
                                      //       ),
                                      ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      _buildMessageInput(),
                    ],
                  ),
          ));
  }

  void _scrollToBottomAnimated() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  Future<void> _filterSearchResults(String query) async {
    if (hubConnection.state == HubConnectionState.Connected &&
        query.isNotEmpty) {
      try {
        await hubConnection.invoke("SearchUsers", args: [query]);
      } catch (e) {
        print("SignalR invoke 오류: ${e.toString()}");
      }
    } else {
      if (searchResults.isNotEmpty) {
        // ✅ 필요할 때만 setState() 호출
        setState(() => searchResults = []);
      }
    }
  }

  void _showOverlay() {
    _removeOverlay(); // 🔥 기존 Overlay를 삭제 (중복 방지)

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 🔹 배경 클릭 시 오버레이 닫기
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeOverlay();
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // 🔹 검색 결과 표시
            Positioned(
              top: Platform.isWindows
                  ? kTextTabBarHeight
                  : kTextTabBarHeight + 60,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.white,
                elevation: 3.0,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return searchResults.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("검색 결과 없음",
                                style: TextStyle(color: Colors.black54)),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  print(
                                      '✅ 선택됨: ${searchResults[index]['NAME']}');
                                  setState(() {
                                    if (!chatRooms.any((room) =>
                                        room['CHAT_ROOM_USER_NO'] ==
                                        searchResults[index]['USERID'])) {
                                      searchId = searchResults[index]['USERID'];
                                      _addChatRoom(searchResults[index]);
                                    } else {
                                      _changeChatRoom(chatRooms.firstWhere(
                                        (room) =>
                                            room['CHAT_ROOM_USER_NO'] ==
                                            searchResults[index]['USERID'],
                                        orElse: () => <String, dynamic>{},
                                      ));
                                    }
                                  });
                                  _removeOverlay();
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueAccent,
                                    child: Text(
                                      searchResults[index]['NAME'][0],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    searchResults[index]['NAME'],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    searchResults[index]['DEPARTFULLNAME'],
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              );
                            },
                          );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context, rootOverlay: true).insert(overlayEntry!);
  }

  void _removeOverlay() {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
  }

  Future<void> _addChatRoom(Map<String, dynamic> user) async {
    // var defaultRoom = new Map<String, dynamic>();

    // defaultRoom['CHAT_ROOM_USERS'] = user['USERID'];
    // defaultRoom['IS_READ'] = 0;
    // defaultRoom['LAST_MESSAGE'] = '채팅을 시작하세요.';
    // defaultRoom['UNREAD_COUNT'] = 0;
    // defaultRoom['LAST_MESSAGE_DATE'] = DateTime.now();

    // selectedChatRoom = defaultRoom;

    await hubConnection.invoke("AddChatRoom", args: [
      userData?['PSPSN_NO'],
      user['USERID'],
      chatRoomListPage,
      chatRoomListPageSize
    ]);
  }

  /// 🔍 검색창 위젯
  Widget _buildSearchBar() {
    return TextField(
      cursorColor: Colors.white,
      controller: searchController,
      focusNode: _searchFocusNode,
      onChanged: (value) {
        _filterSearchResults(value);
      },
      decoration: InputDecoration(
        hintText: '채팅 상대 검색...',
        hintStyle: const TextStyle(color: Colors.white),
        border: InputBorder.none,
        prefixIcon: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              searchController.clear(); // 검색어 초기화
              selectedChatRoom == null
                  ? isSearching = true
                  : isSearching = false;
              searchResults.clear();
            });
          },
          child: const Icon(Icons.cancel, color: Colors.white),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  /// 🏷️ 채팅방 제목 (selectedChatRoom이 있으면 제목 표시)
  Widget _buildTitle() {
    return Row(
      children: [
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              isSearching = true;
              searchResults.clear();
              _searchFocusNode.requestFocus();
            });
          },
          child: const Icon(Icons.search, color: Colors.white),
        ),
        const SizedBox(width: 12), // 아이콘과 아바타 사이 간격 추가
        CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Text(
            selectedChatRoom?['CHAT_ROOM_NAME']?.toString() ??
                selectedChatRoom?['CHAT_ROOM_USERS'][0],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8), // 아바타와 텍스트 사이 간격 추가
        Expanded(
          child: Text(
            selectedChatRoom != null
                ? (selectedChatRoom?['CHAT_ROOM_USERS']).toString()
                : "채팅",
            style: const TextStyle(color: Colors.white, fontSize: 18),
            overflow: TextOverflow.ellipsis, // 너무 길면 ... 처리
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle),
            color: Colors.black54,
            style: const ButtonStyle(iconSize: WidgetStatePropertyAll(30)),
            onPressed: () {},
          ),
          const SizedBox(width: 2),
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) async {
                if (messageController.text.isNotEmpty) {
                  await hubConnection.invoke("SetMessages", args: [
                    selectedChatRoom?['CHAT_ROOM_ID'],
                    userData?['PSPSN_NO'],
                    userData?['SYUSR_NAME'],
                    messageController.text,
                    'TEXT',
                    offset
                  ]);

                  setState(() {
                    //   Map<String, dynamic> newMessage =
                    //       new Map<String, dynamic>();
                    //   newMessage['SENDER_ID'] = userData?['PSPSN_NO'];
                    //   newMessage['MESSAGE'] = messageController.text;
                    //   messages.add(newMessage);
                    messageController.clear();
                    isSearching = false;
                    searchResults.clear();
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottomAnimated();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(String text) {
    final RegExp urlRegex = RegExp(
      r'(https?:\/\/[\w\d\-]+\.[\w\d\-]+(?:\.[\w]{2,})?(?:\/\S*)?)',
      caseSensitive: false,
    );

    final matches = urlRegex.allMatches(text);
    final List<TextSpan> spans = [];
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ));
      }

      final urlText = match.group(0)!;
      spans.add(TextSpan(
        text: urlText,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final Uri url = Uri.parse(urlText);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              print("⚠️ URL 열기 실패: $urlText");
            }
          },
      ));

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
