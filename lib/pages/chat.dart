import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nk_push_app/Utils/util.dart';
import 'package:nk_push_app/constants/url_constants.dart';
import 'package:nk_push_app/frame/navigation_fab_frame.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/signalr_client.dart';

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
    super.dispose();
  }

  void leaveChatRoom() async {
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
            var nestedList = result.first as List<dynamic>;
            var tempMessages = nestedList.cast<Map<String, dynamic>>();

            setState(() {
              messages = tempMessages;
            });

            markMessagesAsRead();

            // 프레임이 완료된 후 스크롤을 아래로 이동
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottomAnimated();
            });
          } else {
            print("Unexpected data format inside list: ${result.first}");
          }
        } else {
          print("Unexpected data format: $result");
        }
      } catch (e) {
        print("ChatRoomListResults 처리 중 오류: $e");
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
    await Future.delayed(const Duration(seconds: 2));
    try {
      await hubConnection.start();
      setState(() {
        connectionId = hubConnection.connectionId; // connectionId 저장
      });
      Util.showSnackBar(context, "재연결 성공!");
    } catch (e) {
      Util.showSnackBar(context, "재연결 실패: ${e.toString()}");
    }
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
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: messages.length,
                          itemBuilder: (context, index) => ListTile(
                            title: Align(
                              alignment: userData?['PSPSN_NO'] ==
                                      messages[index]['SENDER_ID']
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min, // 내용 크기에 맞게 Row 크기 조정
                                crossAxisAlignment:
                                    CrossAxisAlignment.end, // 아래쪽 정렬
                                children: [
                                  Container(
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.7), // 최대 너비 70%
                                    padding: const EdgeInsets.all(12),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: userData?['PSPSN_NO'] ==
                                              messages[index]['SENDER_ID']
                                          ? Colors.blue[100]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      messages[index]['MESSAGE'],
                                      overflow: TextOverflow.visible,
                                      softWrap: true,
                                    ),
                                  ),
                                  const SizedBox(width: 4), // 말풍선과 숫자 사이 간격
                                  Text(
                                    (messages[index]['UNREAD_COUNT'] ?? 0) > 0
                                        ? messages[index]['UNREAD_COUNT']
                                            .toString()
                                        : "",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
}
