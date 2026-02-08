// ignore_for_file: file_names

import 'dart:async';
import 'dart:developer';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:eClassify/data/cubits/chat/get_seller_chat_users_cubit.dart';
import 'package:eClassify/data/cubits/chat/load_chat_messages.dart';
import 'package:eClassify/data/cubits/chat/send_message.dart';
import 'package:eClassify/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:eClassify/data/model/chat/chat_message_modal.dart';
import 'package:eClassify/data/model/chat/chat_user_model.dart';
import 'package:eClassify/data/model/localized_string.dart';
import 'package:eClassify/ui/screens/chat/chat_audio/widgets/chat_widget.dart';
import 'package:eClassify/ui/screens/chat/chat_screen.dart';
import 'package:eClassify/ui/screens/item/my_items_screen.dart';
import 'package:eClassify/ui/screens/main_activity.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/notification/chat_message_handler.dart';
import 'package:eClassify/utils/notification/notification_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String currentlyChattingWith = "";
String currentlyChatItemId = "";

// Todo(I): Needs further improvements and refactoring
abstract class NotificationHandler {
  static String? _getPrice(dynamic price) {
    if (price == null || price.toString().isEmpty) return null;
    if (price is String || price is int || price is double) {
      return price.toString();
    }
    return null;
  }

  static double? _getOfferPrice(dynamic price) {
    if (price == null || price.toString().isEmpty) {
      return null;
    }
    if (price is String) {
      return double.tryParse(price);
    }
    if (price is int) {
      return price.toDouble();
    }
    if (price is double) {
      return price;
    }
    return null; // In case of unexpected types
  }

  // These are side effects
  static void handleSideEffects(
    BuildContext context,
    NotificationType type,
    Map<String, dynamic> data,
  ) {
    print('Handle Side Effects: ${data}');
    if (!context.mounted) return;

    if (type case NotificationType.itemUpdate || NotificationType.itemEdit) {
      (context).read<FetchMyItemsCubit>().fetchMyItems(
        getItemsWithStatus: selectItemStatus,
      );
    }

    if (type == NotificationType.chat) {
      var username = data['user_name'];
      var itemImage = data['item_image'];
      var itemName = data['item_name'];
      var userProfile = data['user_profile'];
      var senderId = data['user_id'];
      var itemId = data['item_id'];
      var date = data['created_at'];
      var itemOfferId = data['item_offer_id'];
      var itemPrice = data['item_price'];
      var itemOfferPrice = data['item_offer_amount'];
      var userType = data['user_type'];

      log('${data}');
      log('$currentlyChattingWith $currentlyChatItemId');

      if (senderId == currentlyChattingWith && itemId == currentlyChatItemId) {
        ChatMessageModal chatMessageModel = ChatMessageModal(
          id: int.parse(data['id'] ?? ''),
          updatedAt: data['updated_at'],
          createdAt: data['created_at'],
          itemId: int.parse(data['item_id'] ?? ''),
          audio: data['audio'],
          file: data['file'],
          message: data['message'],
          receiverId: int.parse(HiveUtils.getUserId().toString()),
          senderId: int.parse(data['sender_id'] ?? ''),
        );

        ChatMessageHandler.add(
          BlocProvider(
            create: (context) => SendMessageCubit(),
            child: ChatMessage(
              key: ValueKey(DateTime.now().toString()),
              message: chatMessageModel.message,
              senderId: chatMessageModel.senderId!,
              createdAt: chatMessageModel.createdAt!,
              isSentNow: false,
              updatedAt: chatMessageModel.updatedAt!,
              audio: chatMessageModel.audio,
              file: chatMessageModel.file,
              itemOfferId: chatMessageModel.id!,
            ),
          ),
        );

        totalMessageCount++;
      } else {
        if (userType == "Buyer") {
          (context).read<GetSellerChatListCubit>().addOrUpdateChat(
            ChatUser(
              itemId: itemId is String ? int.parse(itemId) : itemId,
              amount: _getOfferPrice(itemOfferPrice),
              createdAt: date,
              userBlocked: false,
              id: int.parse(itemOfferId),
              updatedAt: date,
              lastMessageTime: DateTime.now().toString(),
              item: Item(
                id: int.parse(itemId),
                price: itemPrice != null && _getPrice(itemPrice) != null
                    ? double.tryParse(_getPrice(itemPrice)!)
                    : null,
                name: LocalizedString(canonical: itemName),
                image: itemImage,
              ),
              buyerId: int.parse(senderId),
              buyer: Buyer(
                name: username,
                profile: userProfile,
                id: int.parse(senderId),
              ),
              unreadCount: 1,
            ),
          );
        } else {
          (context).read<GetBuyerChatListCubit>().addOrUpdateChat(
            ChatUser(
              itemId: itemId is String ? int.parse(itemId) : itemId,
              userBlocked: false,
              amount: _getOfferPrice(itemOfferPrice),
              createdAt: date,
              id: int.parse(itemOfferId),
              sellerId: int.parse(senderId),
              updatedAt: date,
              lastMessageTime: DateTime.now().toString(),
              item: Item(
                id: int.parse(itemId),
                price: itemPrice != null && _getPrice(itemPrice) != null
                    ? double.tryParse(_getPrice(itemPrice)!)
                    : null,
                name: LocalizedString(canonical: itemName),
                image: itemImage,
              ),
              seller: Seller(
                name: username,
                profile: userProfile,
                id: int.parse(senderId),
              ),
              unreadCount: 1,
            ),
          );
        }
      }
    }
  }

  static void handleNotification(
    BuildContext context,
    NotificationType type,
    Map<String, dynamic> data,
  ) {
    if (!context.mounted) return;
    print('Handling Notification: ${data}');
    if (type == NotificationType.chat) {
      // This block of code fixes the following bug:
      // When user already on the chat page and receive new messages and
      // tap the notification it opens new new window because of this multiple windows are open.
      // and that msg indicator is also not removed.
      if (currentlyChatItemId == data['item_id'] &&
          currentlyChattingWith == data['sender_id']) {
        final userType = data['user_type'];
        final itemOfferId = int.tryParse(data['item_offer_id']);
        if (itemOfferId == null) return;
        if (userType == "Buyer") {
          context.read<GetSellerChatListCubit>().removeUnreadCount(itemOfferId);
        } else {
          context.read<GetBuyerChatListCubit>().removeUnreadCount(itemOfferId);
        }
        return;
      }
      var username = data['user_name'];
      var itemTitleImage = data['item_title_image'];
      var itemTitle = data['item_title'];
      var userProfile = data['user_profile'];
      var senderId = data['sender_id'];
      var itemId = data['item_id'];
      var date = data['created_at'];
      var itemOfferId = data['item_offer_id'];
      var itemPrice = data['item_price'];
      var itemOfferPrice = data['item_offer_amount'] ?? null;
      Future.delayed(Duration.zero, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => SendMessageCubit()),
                  BlocProvider(create: (context) => LoadChatMessagesCubit()),
                ],
                child: Builder(
                  builder: (context) {
                    return ChatScreen(
                      profilePicture: userProfile ?? "",
                      userName: username ?? "",
                      itemImage: itemTitleImage ?? "",
                      itemTitle: itemTitle ?? "",
                      userId: senderId ?? "",
                      itemId: itemId ?? "",
                      date: date ?? "",
                      itemOfferId: int.parse(itemOfferId),
                      itemPrice: _getPrice(itemPrice)!,
                      itemOfferPrice: _getOfferPrice(itemOfferPrice),
                      buyerId: HiveUtils.getUserId(),
                      alreadyReview: false,
                      isPurchased: 0,
                      from: 'notification',
                    );
                  },
                ),
              );
            },
          ),
        );
      });
    } else if (type == NotificationType.offer) {
      if (HiveUtils.isUserAuthenticated()) {
        var username = data['user_name'];
        var itemTitleImage = data['item_title_image'];
        var itemTitle = data['item_title'];
        var userProfile = data['user_profile'];
        var senderId = data['sender_id'];
        var itemId = data['item_id'];
        var date = data['created_at'];
        var itemOfferId = data['item_offer_id'];
        var itemPrice = data['item_price'];
        var itemOfferPrice = data['item_offer_amount'] ?? null;
        Future.delayed(Duration.zero, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (context) => SendMessageCubit()),
                    BlocProvider(create: (context) => LoadChatMessagesCubit()),
                  ],
                  child: Builder(
                    builder: (context) {
                      return ChatScreen(
                        profilePicture: userProfile ?? "",
                        userName: username ?? "",
                        itemImage: itemTitleImage ?? "",
                        itemTitle: itemTitle ?? "",
                        userId: senderId ?? "",
                        itemId: itemId ?? "",
                        date: date ?? "",
                        itemOfferId: int.parse(itemOfferId),
                        itemPrice: _getPrice(itemPrice)!,
                        itemOfferPrice: _getOfferPrice(itemOfferPrice),
                        buyerId: HiveUtils.getUserId(),
                        alreadyReview: false,
                        isPurchased: 0,
                        from: 'notification',
                      );
                    },
                  ),
                );
              },
            ),
          );
        });
      } else {
        Future.delayed(Duration.zero, () {
          HelperUtils.goToNextPage(Routes.notificationPage, context, false);
        });
      }
    } else if (type == NotificationType.itemUpdate) {
      MainActivity.globalKey.currentState?.onItemTapped(2);
    } else if (type == NotificationType.itemEdit) {
      var id = int.tryParse(data["item_id"]);
      if (id == null) return;
      Navigator.pushNamed(
        context,
        Routes.adDetailsScreen,
        arguments: {'item_id': id},
      );
    } else if (type == NotificationType.jobApplication) {
      Future.delayed(Duration.zero, () {
        Navigator.pushNamed(
          context,
          Routes.jobApplicationList,
          arguments: {'itemId': int.tryParse(data['item_id'] ?? '') ?? 0},
        );
      });
    } else if (type == NotificationType.applicationStatus) {
      Navigator.pushNamed(
        context,
        Routes.jobApplicationList,
        arguments: {'itemId': 0, 'isMyJobApplications': true},
      );
    } else if (type == NotificationType.payment) {
      if (HiveUtils.isUserAuthenticated()) {
        Future.delayed(Duration.zero, () {
          Navigator.pushNamed(context, Routes.subscriptionPackageListRoute);
        });
      } else {
        Future.delayed(Duration.zero, () {
          HelperUtils.goToNextPage(Routes.notificationPage, context, false);
        });
      }
    } else if (type == NotificationType.verificationStatus) {
      MainActivity.globalKey.currentState?.onItemTapped(3);
    } else if (type == NotificationType.itemReview) {
      MainActivity.globalKey.currentState?.onItemTapped(3);
      HelperUtils.goToNextPage(Routes.myReviewsScreen, context, false);
    } else if (data["item_id"] != null && data["item_id"] != '') {
      var id = int.tryParse(data["item_id"]);
      if (id == null) return;
      Navigator.pushNamed(
        context,
        Routes.adDetailsScreen,
        arguments: {'item_id': id},
      );
    } else {
      HelperUtils.goToNextPage(
        Routes.notificationPage,
        context,
        false,
        args: {'notificationId': data['notification_id'] as String?},
      );
    }
  }
}
